from os import getEnv
from json import parseJson, pairs
from net import CVerifyNone
import asyncnet, asyncdispatch, uri, strutils, lists

include 
  slacktypes,
  slackrequest,
  slackuser,
  slackchannel,
  config


proc initSlackServer*(
    token: string,
    username: string,
    domain: string,
    websocket: AsyncWebSocket,
    loginData: JsonNode,
    connected: bool,
    wsUrl: Uri,
    config: Config,
    users: SinglyLinkedList[SlackUser] = initSinglyLinkedList[SlackUser](),
    channels: SinglyLinkedList[SlackChannel] = initSinglyLinkedList[SlackChannel]()
  ): SlackServer = 
  ## initialises a slack server

  result = SlackServer(token: token, username: username, domain: domain, websocket: websocket,
    loginData: loginData, wsUrl: wsUrl, config: config, users: users, channels: channels)

proc initRTM(request: SlackRequest, domain = "slack.com", token: string): string = 
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

proc didInitSucceed(response: JsonNode): bool = 
  ##Checks to see if the initial login request succeeded
  return response["ok"].getBVal()

proc buildSlackUri(wsUri: Uri, config: Config): Uri =
  result = parseUri(format("$#://$#:$#$#$#", wsUri.scheme, wsUri.hostname, config.WsPort, wsUri.path, wsUri.query))

proc initBotUser(self: SlackServer, selfData: JsonNode) {.discardable.} = 
  var user = initSlackUser(
    user_id = selfData["id"].str,
    name = selfData["name"].str,
    real_name = self.config.BotName,
    email = self.config.BotEmail,
    timezone = self.config.BotTimeZone,
    server = self
    )
  self.users.prepend(newSinglyLinkedNode[SlackUser](user))

proc rtmConnect*(reconnect: bool = false, timeout: int): SlackServer =
  ## Connect or reconnect to the RTM
  ## We have to make an initial request to the HTTP API, which gives us a Websocket URL
  ## and other contextual data
  ##
  ## We use rtm.start instead of connect to build user lists
  ## TODO: Replace .start with .connect and use api calls to build users etc

  echo slackConfigFilePath()
  let config = loadConfig()

  var token = ""
  if isNilOrEmpty(config.BotToken) or isNilOrWhiteSpace(config.BotToken):
    token = string(getEnv("SLACK_BOT_TOKEN"))
    echo token
    if isNilOrEmpty(token) or isNilOrWhiteSpace(token):
      echo "No Bot Token set in config and no SLACK_BOT_TOKEN environment variable"
      quit(1)
  else:
    token = config.BotToken

  var request = initSlackRequest(nil, "")
  var rtm = initRTM(request, token = $token)
  var loginData = parseJson(rtm)
  let domain = loginData["team"]["domain"].str
  let username = loginData["self"]["name"].str

  if not didInitSucceed(loginData):
    # Our init was good!
    echo "FAILURE!"
    quit(0)

  var wsUri = parseUri(loginData["url"].str)
  let serverUrl = buildSlackUri(wsUri, config)

  let ws = waitFor newAsyncWebSocket(serverUrl, sslVerifyMode = CVerifyNone)
  echo "Connected to " & $serverUrl


  result = initSlackServer(
    token = token,
    username = username,
    domain = domain,
    websocket = ws,
    loginData = loginData,
    connected = true,
    wsUrl = serverUrl,
    config = config
  )

  initBotUser(result, loginData["self"])

proc parseChannels(self: SlackServer, channels: JsonNode) {.discardable.} = 
  ## Parses users from a JsonNode of users from a slack login and adds them to the server's list
  var channelList = self.channels

  for channel in channels:
    #TODO: Some channels are bots or apps, so we need to handle those differently in the future
    try:
      if channel["is_channel"].getBVal == false:
        continue
      var newChannel = initSlackChannel(
        channel_id = channel["id"].str,
        name = channel["name"].str,
        server = self
        )
      channelList.prepend(newSinglyLinkedNode[Slackchannel](newChannel))
    except KeyError:
      echo "Invalid channel data for channel $#" % channel["name"].str
      continue

proc parseUsers(self: SlackServer, users: JsonNode) {.discardable.} = 
  ## Parses users from a JsonNode of users from a slack login and adds them to the server's list
  var userList = self.users

  for user in users:
    #TODO: Some users are bots or apps, so we need to handle those differently in the future
    try:
      var newUser = initSlackUser(
        user_id = user["id"].str,
        name = user["name"].str,
        real_name = user["real_name"].str,
        email = user["profile"]["email"].str,
        timezone = user["tz"].str,
        server = self
        )
      userList.prepend(newSinglyLinkedNode[SlackUser](newUser))
    except KeyError:
      echo "Invalid user data for user $#" % user["name"].str
      continue

proc parseLoginData*(self: SlackServer, loginData: JsonNode) {.discardable.} =
  parseUsers(self, loginData["users"])
  parseChannels(self, loginData["channels"])

proc loop*(self: SlackServer) {.discardable.} = 
  ## The main event loop. Reads data from slack's RTM
  
  let ws = self.websocket

  proc reader() {.async.} =
    while true:
      let read = await ws.sock.readData(true)
      echo "read: " & $read

  proc ping() {.async.} =
    while true:
      await sleepAsync(6000)
      echo "ping"
      await ws.sock.sendPing(true)

  asyncCheck reader()
  asyncCheck ping()
  runForever()
  
#proc initSlackServer*(token: string, connect: bool, proxy: Proxy): SlackServer =

