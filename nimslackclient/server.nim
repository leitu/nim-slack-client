from json import parseJson, pairs
from net import CVerifyNone
import asyncnet, asyncdispatch, uri, strutils, lists, httpclient
import events

include 
  slacktypes,
  slackrequest,
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

proc initRTM(request: SlackRequest, domain = "slack.com", token: string, payload: JsonNode = newJObject()): string = 
  ## Make an initial connection to slack and return a success string or failure string
  ##
  var data = newMultiPartData()

  var client = newHttpClient()

  #We use start so that we can get lists of users and other useful stuff
  let url = "https://" & domain & "/api/rtm.start"
  client.headers = newHttpHeaders({
      "user-agent": getUserAgent(request),
      "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    })

  data["token"] = token
  
  return client.postContent(url, multipart = data)

proc appendUserAgent(self: SlackServer, name, version: string): SlackServer = 
  self.apiRequester.appendUserAgent(name, version)
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

  var counter = 1
  for user in users:
    if user.hasKey("deleted") and user["deleted"].getBool() == true:
      echo "Skipping deleted user " & $user["name"].str
      continue

    #TODO: Some users are bots or apps, so we need to handle those differently in the future
    var email = if user.hasKey("profile") and user["profile"].hasKey("email"): user["profile"]["email"].getStr("") else: ""
    var real_name = if user.hasKey("real_name"): user["real_name"].getStr("") else: ""
    var tz = if user.hasKey("tz"): Timezone(zone: user["tz"].getStr("UTC")) else: Timezone(zone: "UTC")
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

proc parseLoginData*(self: var SlackServer, loginData: JsonNode) {.discardable.} =
  parseUsers(self, loginData["users"])
  parseChannels(self, loginData["channels"])

proc rtmConnect*(self: var SlackServer, reconnect: bool = false, proxies: seq[Proxy] = @[], payload: JsonNode = newJObject()): SlackServer {.discardable.} =
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
  var rtm = initRTM(request, token=token, payload=payload)
  var loginData = parseJson(rtm)

  if not didInitSucceed(loginData):
    # Our init was good!
    echo "FAILURE!"
    quit(0)

  var wsUri = parseUri(loginData["url"].str)
  let serverUrl = buildSlackUri(wsUri, config)

  let ws = waitFor newAsyncWebSocket(serverUrl, verifySsl = false)

  new(result)

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

proc rtmConnect*(reconnect: bool = false, proxies: seq[Proxy] = @[], payload: JsonNode = newJObject()): SlackServer {.discardable.} =
  ## Connect or reconnect to the RTM
  ## We have to make an initial request to the HTTP API, which gives us a Websocket URL
  ## and other contextual data
  ##
  ## We use rtm.start instead of connect to build user lists
  ## TODO: Replace .start with .connect and use api calls to build users etc

  let config = loadConfig()

  var token = ""
  if isNilOrEmpty(token):
    token = config.getSlackBotToken()

  let request = initSlackRequest(proxies=proxies)
  var rtm = initRTM(request, token=token, payload=payload)
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

  new(result)

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

  if isNil(thread) == true:
    echo "WOW"
    quit(1)

  var msg = """{"type": "message", "channel": "$#", "text": "$#"}""" % [$channel, message]
  echo msg

  var messageJson = parseJson(msg)

  if isNil(thread) == false:
    messageJson["thread_ts"] = %* thread
    if reply_broadcast:
      messageJson["reply_broadcast"] = %* true

  #Send the message to be sent via the websocket
  self.sendToWebSocket(messageJson)

proc `Type=`*(self: var SlackMessage, data: string) {.inline.} = 
  self.Type = data

proc `Channel=`*(self: var SlackMessage, data: SlackChannel) {.inline.} =
  self.Channel = data

proc `Channel=`*(self: var SlackMessage, data: SlackUser) {.inline.} =
  self.User = data

proc `Text=`*(self: var SlackMessage, data: string) {.inline.} =
  self.Text = data

proc `TimeStamp=`*(self: var SlackMessage, data: string) {.inline.} =
  self.TimeStamp = data

proc buildSlackMessage*(self: SlackServer, data: JsonNode): SlackMessage = 
  let MESSAGETEXT = re"^<@\w*?> (.*)"

  new(result)

  var isMessage = false
  var acceptedType = "message"

  result.Type = data["type"].str
  if data["type"].str == "message":
    isMessage = true
    echo "Is message type!"

  if isMessage:
    echo "MESSAGE!"

  if data.hasKey("text"):
    if data["text"].str.contains(MESSAGETEXT):
      result.Text = data["text"].str.match(MESSAGETEXT).get.captures[0]

  if data.hasKey("ts"):
    result.TimeStamp = data["ts"].str
    
  var hasMatch = false
  if data.hasKey("user"):
    if isMessage:
      echo "User data " & data["user"].str
    for u in items(self.users):
      if isMessage:
        echo "User iter " & u.id
      if u.id == data["user"].str:
        hasMatch = true
        result.User = u
        echo "Breaking, found user " & result.User.name
        break

  if data.hasKey("channel"):
    for c in self.channels.items():
      if c.id == data["channel"].str:
        result.Channel = c
        break
  
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
