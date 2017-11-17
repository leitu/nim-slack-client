import json
import httpclient 
from strutils import toLowerAscii
from sequtils import any
import server
from slackrequest import appendUserAgent
import slacktypes
import slackchannel


proc rtmConnect(self: SlackClient, token: string, with_team_state: bool = false, payload: JsonNode = newJObject(), proxies: seq[Proxy] = newSeq[Proxy](0)): SlackClient = 
  new result
  result = self
  try:
    result.server = rtmConnect(use_rtm_start=with_team_state, payload=payload, proxies=proxies)
  except:
    echo "Failed to connect"

proc newSlackClient*(token: string, proxies: seq[Proxy]): SlackClient = 
  new result

  result.token = token
  result = rtmConnect(result, token=token, proxies=proxies)

proc appendUserAgent*(self: SlackClient, name, version: string): SlackClient =
  new result
  result.token = self.token
  result.server = self.server
  result.server.apiRequester = self.server.apiRequester.appendUserAgent(name=name, version=version)


proc apiCall(self: SlackClient, request: string, timeout: int, payload: JsonNode = newJObject()): SlackMessage = 
  result = self.server.apiCall(request=request, timeout=timeout, payload=payload)
  echo $(result.ok)
  echo result.text
  
  case result.msgType.toLowerAscii
    of "im.open":
      if result.ok and result.ok == true:
        discard self.server.attachChannel(result.user.name, result.channel.id)
    of "mpim.open", "groups.create", "groups.createchild":
      if result.ok and result.ok == true:
        discard self.server.attachChannel(
          name=result.user.name,
          user_id=result.user.id,
          members=payload["group"]["members"]
        )
    of "channels.create", "channels.join":
      if result.ok and result.ok == true:
        discard self.server.attachChannel(
          payload["channel"]["name"].getStr(),
          payload["channel"]["id"].getStr(),
          payload["channel"]["members"].getStr()
        )
    else:
      echo "Message Type: " & result.msgType

proc sendRTMMessage*(self: SlackClient, channel, message: string, thread: string = "", reply_broadcast: bool = false): int {.discardable.} =
  #[
  # Sends a message to the slack RTM
  ]#

  var slackChannel = findChannelById(channel_id=channel, server=self.server)
  if isNil(slackChannel):
    slackChannel = initSlackChannel(channel_id=channel, server=self.server)

  return self.server.sendRTMMessage(
      channel=slackChannel,
      message=message, thread=thread,
      reply_broadcast=reply_broadcast
    )




  
    


  

