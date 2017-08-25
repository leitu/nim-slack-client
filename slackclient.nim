import json, tables, strutils, httpclient

type
  SlackRequest* = ref object of RootObj
    defaultUserAgent: Table[string, string]
    customUserAgent: seq[string]
    proxy: Proxy


proc initSlackRequest*(proxy: Proxy, customAgent: string): SlackRequest = 

  var defaultsUA = initTable[string, string]()
  defaultsUA["client"] = "nimslackclient/0.1"
  defaultsUA["nim"] = "Nim/0.17.0"
  defaultsUA["system"] = hostOS & "/"

  result = SlackRequest(proxy: proxy, defaultUserAgent: defaultsUA, customUserAgent: customAgent)

proc getUserAgent(self: SlackRequest): string = 

  if len(self.customUserAgent) > 0:
    var customUaList = newSeq[string](0)
    for uaString in self.customUserAgent:
      customUaList.add(join(uaString, "/"))
    let customUaString = join(customUaList, " " )
    self.defaultUserAgent["custom"] = customUaString

  var uaString = newSeq[string](0)
  for ua in values(self.defaultUserAgent):
    uaString.add(ua)

  result = join(uaString, " ")

proc appendUserAgent(self: SlackRequest, name: string, version: string): {.discardable.} = 

