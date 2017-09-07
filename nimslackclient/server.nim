from os import getEnv
from json import parseJson, pairs
from net import CVerifyNone
import asyncnet, asyncdispatch, uri, strutils, lists

include 
  slacktypes,
  slackrequest,
  slackuser


proc initSlackServer*(
    token: string,
    username: string,
    domain: string,
    websocket: AsyncWebSocket,
    loginData: JsonNode,
    connected: bool,
    wsUrl: Uri,
    users: SinglyLinkedList[SlackUser] = initSinglyLinkedList[SlackUser](),
    channels: SinglyLinkedList[SlackChannel] = initSinglyLinkedList[SlackChannel]()
  ): SlackServer = 
  ## initialises a slack server

  result = SlackServer(token: token, username: username, domain: domain, websocket: websocket,
    loginData: loginData, users: users, channels: channels, wsUrl: wsUrl)

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

proc buildSlackUri(wsUri: Uri): Uri =
  let WS_PORT = 443
  result = parseUri(format("$#://$#:$#$#$#", wsUri.scheme, wsUri.hostname, $WS_PORT, wsUri.path, wsUri.query))

proc initBotUser(self: SlackServer, selfData: JsonNode) {.discardable.} = 
  var user = initSlackUser(
    user_id = int(selfData["id"].getNum),
    name = selfData["name"].str,
    real_name = "BOT",
    email = "ryanc@signiq.com",
    timezone = "Australia/Perth",
    server = self
    )
  self.users.prepend(newSinglyLinkedNode[SlackUser](user))

proc rtmConnect*(reconnect: bool = false, timeout: int): SlackServer =
  ## Connect or reconnect to the RTM

  if existsEnv("SLACK_BOT_TOKEN") == false:
    echo "No SLACK_BOT_TOKEN environment variable"
    quit(1)

  var token = string(getEnv("SLACK_BOT_TOKEN"))

  var request = initSlackRequest(nil, "")
  var rtm = initRTM(request, token = $token)
  var loginData = parseJson(rtm)
  let domain = loginData["team"]["domain"].str

  if not didInitSucceed(loginData):
    # Our init was good!
    echo "FAILURE!"
    quit(0)

  var wsUri = parseUri(loginData["url"].str)
  let serverUrl = buildSlackUri(wsUri)
  echo serverUrl

  let ws = waitFor newAsyncWebSocket(serverUrl, sslVerifyMode = CVerifyNone)
  echo "Connected to " & $serverUrl


  result = initSlackServer(
    token = token,
    username = "SodaBot",
    domain = domain,
    websocket = ws,
    loginData = loginData,
    connected = true,
    wsUrl = serverUrl
  )

  initBotUser(result, loginData["self"])


proc parseUsers*(self: SlackServer, users: JsonNode) {.discardable.} = 
  ## Parses users from a JsonNode of users from a slack login and adds them to the server's list
  var userList = self.users

  for user in users:
    #TODO: Some users are bots or apps, so we need to handle those differently in the future
    try:
      var newUser = initSlackUser(
        user_id = int(user["id"].getNum),
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

