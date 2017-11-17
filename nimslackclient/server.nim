import typetraits
import json
import asyncnet, asyncdispatch, uri, strutils, lists, httpclient
import events
import websocket
import slackrequest
from slackmessage import buildSlackMessage

import 
  slacktypes,
  slackuser,
  slackchannel,
  config,
  nre

proc initSlackServer*(
    token: string,
    username: string,
    domain: string,
    websocket: AsyncWebSocket,
    loginData: JsonNode,
    connected: bool,
    wsUrl: Uri,
    config: Config,
    proxies: seq[Proxy],
    apiRequester: SlackRequest
  ): SlackServer = 
  ## initialises a slack server

  new result
  result.token = token
  result.username = username
  result.domain = domain
  result.websocket = websocket
  result.loginData = loginData
  result.wsUrl = wsUrl
  result.config = config
  result.users = initSinglyLinkedList[SlackUser]()
  if proxies.len > 0:
    result.proxies = proxies
  result.channels = initSinglyLinkedList[SlackChannel]()
  result.apiRequester = initSlackRequest(proxies=proxies)

proc initRTM(request: SlackRequest, domain = "slack.com", token: string, payload: JsonNode = newJObject(), use_rtm_start=false): string = 
  ## Make an initial connection to slack and return a success string or failure string
  ##
  var data = newMultiPartData()

  var client = newHttpClient()

  #We use start so that we can get lists of users and other useful stuff
  let url = "https://" & domain & "/api/" & (if use_rtm_start: "rtm.start" else: "rtm.connect")
  client.headers = newHttpHeaders({
      "user-agent": request.getUserAgent(),
      "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    })

  data["token"] = token
  
  return client.postContent(url, multipart = data)

proc appendUserAgent*(self: SlackServer, name, version: string): SlackServer = 
  self.apiRequester.appendUserAgent(name=name, version=version)
  self

proc didInitSucceed(response: JsonNode): bool = 
  ##Checks to see if the initial login request succeeded
  return response["ok"].getBool()

proc buildSlackUri(wsUri: Uri, config: Config): Uri =
  result = parseUri(format("$#://$#:$#$#$#", wsUri.scheme, wsUri.hostname, config.WsPort, wsUri.path, wsUri.query))

proc initBotUser(self: var SlackServer, selfData: JsonNode) {.discardable.} = 
  var user = SlackUser(id: selfData["id"].str, name: selfData["name"].str, real_name: self.config.BotName, email: self.config.BotEmail, timezone: Timezone(zone: self.config.BotTimeZone), server: self)
  self.users.prepend(user)

proc parseChannels(self: var SlackServer, channels: JsonNode) {.discardable.} = 
  ## Parses users from a JsonNode of users from a slack login and adds them to the server's list
  var channelList = self.channels

  for channel in channels:
    #TODO: Some channels are bots or apps, so we need to handle those differently in the future
    try:
      if channel["is_channel"].getBool == false:
        continue

      var newChannel = initSlackChannel(
        channel_id=channel["id"].str,
        name=channel["name"].getStr(""),
        server=self
        )
      channelList.prepend(newSinglyLinkedNode[Slackchannel](newChannel))
    except KeyError:
      echo "Invalid channel data for channel $#" % channel["name"].str
      continue

proc parseUsers(self: var SlackServer, users: JsonNode) {.discardable.} = 
  ## Parses users from a JsonNode of users from a slack login and adds them to the server's list
  var userList = self.users
  var email, real_name:string
  var tz: TimeZone

  var counter = 1
  for user in users:
    if user.hasKey("deleted") and user["deleted"].getBool() == true:
      echo "Skipping deleted user " & $user["name"].str
      continue

    #TODO: Some users are bots or apps, so we need to handle those differently in the future
    email = if user.hasKey("profile") and user["profile"].hasKey("email"): user["profile"]["email"].getStr("") else: ""
    real_name = if user.hasKey("real_name"): user["real_name"].getStr("") else: ""
    tz = if user.hasKey("tz"): Timezone(zone: user["tz"].getStr("UTC")) else: Timezone(zone: "UTC")
    var newUser = initSlackUser(
      user_id=user["id"].str,
      name=user["name"].str,
      real_name=real_name,
      email=email,
      timezone=tz,
      server=self
      )
    counter += 1
    userList.prepend(newUser)

proc attachUser*(self: SlackServer, name, user_id, real_name, tz: string): SlackServer = 
  new result
  result = self
  result.users.prepend(initSlackUser(user_id=user_id, name=name, real_name=real_name, timezone=tz, server=result))

proc attachChannel*(self: SlackServer, name, user_id, tz: string = "UTC", members: JsonNode = newJObject()): SlackServer = 
  new result
  result = self

  let channel = initSlackChannel(channel_id=user_id, name=name, server=result)
  if isNil(self.channels.find(channel)) == false:
    result.channels.prepend(channel)

proc parseLoginData*(self: var SlackServer, loginData: JsonNode) {.discardable.} =
  parseUsers(self, loginData["users"])
  parseChannels(self, loginData["channels"])

proc rtmConnect*(self: var SlackServer, reconnect: bool = false, use_rtm_start:bool = false, proxies: seq[Proxy] = @[], payload: JsonNode = newJObject()): SlackServer {.discardable.} =
  ## Connect or reconnect to the RTM
  ## We have to make an initial request to the HTTP API, which gives us a Websocket URL
  ## and other contextual data
  ##
  ## We use rtm.start instead of connect to build user lists
  ## TODO: Replace .start with .connect and use api calls to build users etc

  let config = loadConfig()

  var token = self.token
  if isNilOrEmpty(token):
    token = config.getSlackBotToken()

  var request = initSlackRequest(proxies)
  var rtm = initRTM(request, token=token, use_rtm_start=use_rtm_start, payload=payload)
  var loginData = parseJson(rtm)

  if not didInitSucceed(loginData):
    # Our init was good!
    echo "FAILURE!"
    quit(0)

  var wsUri = parseUri(loginData["url"].str)
  let serverUrl = buildSlackUri(wsUri, config)

  let ws = waitFor newAsyncWebSocket(serverUrl, verifySsl = false)


  if reconnect == true:
    echo "Reconnected to " & $serverUrl

    result = initSlackServer(
      token = self.token,
      username = self.username,
      domain = self.domain,
      websocket = ws,
      loginData = self.loginData,
      connected = self.connected,
      wsUrl = self.wsUrl,
      config = self.config,
      proxies = self.proxies,
      apiRequester = request
    )
  else:
    echo "Connected to " & $serverUrl
    result = initSlackServer(
      token = self.token,
      username = self.username,
      domain = self.domain,
      websocket = ws,
      loginData = self.loginData,
      connected = self.connected,
      wsUrl = self.wsUrl,
      config = self.config,
      proxies = self.proxies,
      apiRequester = request
    )
    initBotUser(result, loginData["self"])
    parseLoginData(result, loginData)

proc rtmConnect*(reconnect: bool = false, proxies: seq[Proxy] = @[], payload: JsonNode = newJObject(), use_rtm_start: bool = false): SlackServer {.discardable.} =
  ## Connect or reconnect to the RTM
  ## We have to make an initial request to the HTTP API, which gives us a Websocket URL
  ## and other contextual data
  ##
  ## We use rtm.start instead of connect to build user lists
  ## TODO: Replace .start with .connect and use api calls to build users etc
  new result

  let config = loadConfig()

  var token = ""
  if isNilOrEmpty(token):
    token = config.getSlackBotToken()

  let request = initSlackRequest(proxies=proxies)
  var rtm = initRTM(request, token=token, payload=payload, use_rtm_start=use_rtm_start)
  var loginData = parseJson(rtm)
  let domain = loginData["team"]["domain"].str
  let username = loginData["self"]["name"].str

  if not didInitSucceed(loginData):
    # Our init was good!
    echo "FAILURE!"
    quit(0)

  var wsUri = parseUri(loginData["url"].str)
  let serverUrl = buildSlackUri(wsUri, config)

  let ws = waitFor newAsyncWebSocket(serverUrl, verifySsl = false)


  if reconnect == true:
    echo "Reconnected to " & $serverUrl
    result = initSlackServer(
      token = token,
      username = username,
      domain = domain,
      websocket = ws,
      loginData = loginData,
      connected = true,
      wsUrl = serverUrl,
      config = config,
      proxies = proxies,
      apiRequester = request
    )

  else:
    echo "Connected to " & $serverUrl

    result = initSlackServer(
      token = token,
      username = username,
      domain = domain,
      websocket = ws,
      loginData = loginData,
      connected = true,
      wsUrl = serverUrl,
      config = config,
      proxies = proxies,
      apiRequester = request
    )

    initBotUser(result, loginData["self"])
    parseLoginData(result, loginData)

proc sendToWebSocket(self: var SlackServer, messageJson: JsonNode) {.discardable.} =
  ##Sends a text message to the RTM websockets
  try:
    discard self.websocket.sock.sendText($messageJson, false)
  except:
    self = self.rtmConnect(reconnect=true)

proc sendRTMMessage*(self: var SlackServer, channel: SlackChannel, message: string, thread: string = "", reply_broadcast: bool = false): int {.discardable.} =
  ## Sends a message to a given channel

  var msg = """{"type": "message", "channel": "$#", "text": "$#"}""" % [$channel, message]

  var messageJson = parseJson(msg)

  if isNil(thread) == false:
    messageJson["thread_ts"] = %* thread
    if reply_broadcast:
      messageJson["reply_broadcast"] = %* true

  #Send the message to be sent via the websocket
  self.sendToWebSocket(messageJson)

proc apiCall*(self: SlackServer, request: string, timeout: int, payload: JsonNode = newJObject()): SlackMessage = 
  self.apiRequester.sendRequest(token=self.token, server=self, request=request, data=payload, timeout=timeout)

### Callbacks

proc reader(ws: AsyncWebSocket) {.async.} =
  while true:
    let read = await ws.sock.readData(true)
    echo "read: " & $read

proc ping(ws: AsyncWebSocket) {.async.} =
  while true:
    await sleepAsync(6000)
    echo "ping"
    await ws.sock.sendPing(true)

proc serve*(self: SlackServer) {.async.} = 
  ## The main event loop. Reads data from slack's RTM
  ## Individual implementations should define their own loop
  
  let ws = self.websocket

  asyncCheck reader(ws)
  asyncCheck ping(ws)

  runForever()
