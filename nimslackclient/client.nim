
include 
  slacktypes,
  slackserver

proc newSlackClient*(token: string, proxies: seq[Proxy]): SlackClient = 
  new result

  result.token = token
  result.server = rtmConnect(proxies=proxies)

proc appendUserAgent(self: ref SlackClient, name, version: string): SlackClient =
  self.server.apiRequester.appendUserAgent(name, version)


