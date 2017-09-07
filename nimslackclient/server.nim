from os import getEnv
from json import parseJson, pairs
from net import CVerifyNone
import asyncnet, asyncdispatch, uri, strutils

include 
  slacktypes,
  slackrequest,
  slackuser

const SLACKDOMAIN = "slack-msgs.com"
const HTTPSPORT = ":443"

proc initSlackServer*(
    token: string,
    username: string,
    domain: string,
    websocket: AsyncWebSocket,
    loginData: JsonNode,
    connected: bool,
    wsUrl: Uri,
    users: SinglyLinkedList[SlackUser] = SinglyLinkedList[SlackUser](),
    channels: SinglyLinkedList[SlackChannel] = SinglyLinkedList[SlackChannel]()
  ): SlackServer = 
  ## initialises a slack server

  result = SlackServer(token: token, username: username, domain: domain, websocket: websocket,
    loginData: loginData, users: users, channels: channels, wsUrl: wsUrl)

proc initRTM(request: SlackRequest, domain = "slack.com", token: string): string = 
  ## Make an initial connection to slack and return a success string or failure string
  ##
  var data = newMultiPartData()

  var client = newHttpClient()

  let url = "https://" & domain & "/api/rtm.connect"
  client.headers = newHttpHeaders({
      "user-agent": getUserAgent(request),
      "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    })

  data["token"] = token
  
  return client.postContent(url, multipart = data)

proc didInitSucceed(response: JsonNode): bool = 
  return response["ok"].getBVal()

proc rtmConnect*(reconnect: bool = false, timeout: int): SlackServer =
  ## Connect or reconnect to the RTM


  var token = getEnv("SLACK_BOT_TOKEN")
  var request = initSlackRequest(nil, "")
  var rtm = initRTM(request, token = $token)
  var loginData = parseJson(rtm)

  var user = initSlackUser(
    user_id = loginData["self"]["id"].str,
    name = loginData["self"]["name"].str,
    timezone = "Australia/Perth"
    )

  if not didInitSucceed(loginData):
    # Our init was good!
    echo "FAILURE!"
    quit(0)

  var wsUri = loginData["url"].str 
  var splitUri = split(wsUri, SLACKDOMAIN, 1)

  wsUri = splitUri[0] & SLACKDOMAIN & $HTTPSPORT & splitUri[1]
  echo wsUri

  let serverUrl = parseUri(wsUri)

  let ws = waitFor newAsyncWebSocket(serverUrl, sslVerifyMode = CVerifyNone)
  echo "Connected to !" & $serverUrl



  result = initSlackServer(
    token = token,
    username = user.name,
    domain = SLACKDOMAIN,
    websocket = ws,
    loginData = loginData,
    connected = true,
    wsUrl = serverUrl
  )

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

