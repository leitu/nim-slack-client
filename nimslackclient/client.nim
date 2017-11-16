import json

include 
  slacktypes,
  slackserver

proc newSlackClient*(token: string, proxies: seq[Proxy]): SlackClient = 
  new result

  result.token = token
  result.server = rtmConnect(proxies=proxies)

proc appendUserAgent*(self: ref SlackClient, name, version: string): SlackClient =
  self.server.apiRequester.appendUserAgent(name, version)

proc rtmConnect(self: SlackClient, with_team_state: bool = false, payload: JsonNode): SlackClient = 
  new result
  result = self
  try:
    self.server.rtmConnect(use_rtm_start=with_team_state, payload=payload)
  except:
    echo "Failed to connect"

proc apiCall(self: SlackClient, request: string, timeout: int, payload: JsonNode = newJObject()): SlackMessage = 
  result = self.server.apiCall(request=request, timeout=timeout, payload=payload)

