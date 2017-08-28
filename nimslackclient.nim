from os import getEnv
from json import parseJson, pairs

include 
  nimslackclient/slackrequest,
  nimslackclient/server


var token = getEnv("SLACK_BOT_TOKEN")
var request = initSlackRequest(nil, "")
var rtm = initRTM(request, token = $token)
var js = parseJson(rtm)
if didInitSucceed(js):
  # Our init was good!
  echo "SUCCESS!"
  for key, value in js.pairs:
    echo $key

else:
  quit(1)
