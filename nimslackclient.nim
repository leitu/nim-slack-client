## Sample Websocket URl
## wss://lbmulti-b6u4.lb.slack-msgs.com/websocket/XwNgiYkQkNLNQKf00sMoD-ILTwu2LMp6xWQydsui4fTV9EaYgyE0VlldXTQAUITTjLeOddPslVLEJBGFynnV4gh83i15uG9W5MzLAUN6czg0I5-RN8numlinK53l2xBDwFLSZ6-V9LGr8v-XyL82IgwXeEqXjBL5HfUnGWPVQLg=
## Sample messages:
# {"type":"user_typing","channel":"G64HV5E0Y","user":"U2TM44RN0"})
#read: (opcode: Text, data: {"type":"message","channel":"G64HV5E0Y","user":"U2TM44RN0","text":"<@U64HFLPG9> WOW","ts":"1504772511.000007","source_team":"T03DRH8QZ","team":"T03DRH8QZ"})
#read: (opcode: Text, data: {"type":"desktop_notification","title":"SignIQ","subtitle":"bottystuff","msg":"1504772511.000007","content":"ryanc: @sodabot WOW","channel":"G64HV5E0Y","launchUri":"slack:\/\/channel?id=G64HV5E0Y&message=1504772511000007&team=T03DRH8QZ","avatarImage":"https:\/\/avatars.slack-edge.com\/2017-08-02\/221029099876_496046da12c5ab7c9d86_192.jpg","ssbFilename":"knock_brush.mp3","imageUri":null,"is_shared":false,"event_ts":"1504772511.000132"})
##

from os import getEnv
from json import parseJson, pairs
from net import CVerifyNone
import websocket, asyncnet, asyncdispatch, uri

include 
  nimslackclient/slackrequest,
  nimslackclient/server

const SLACKDOMAIN = "slack-msgs.com"
const HTTPSPORT = ":443"

var token = getEnv("SLACK_BOT_TOKEN")
var request = initSlackRequest(nil, "")
var rtm = initRTM(request, token = $token)
var js = parseJson(rtm)
if not didInitSucceed(js):
  # Our init was good!
  echo "FAILURE!"
  quit(0)

var wsUri = js["url"].str 
var splitUri = split(wsUri, SLACKDOMAIN, 1)

wsUri = splitUri[0] & SLACKDOMAIN & $HTTPSPORT & splitUri[1]
echo wsUri

let serverUrl = parseUri(wsUri)


let ws = waitFor newAsyncWebSocket(serverUrl, sslVerifyMode = CVerifyNone)
echo "Connected to !" & $serverUrl

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
