import slacktypes
import json, tables, strutils, httpclient, os, asyncdispatch

proc initSlackRequest*(proxy: Proxy, customAgent: string): SlackRequest = 
  ## Create and return a default slack request

  var customAgentSeq = newSeq[string](0)
  var defaultsUA = initTable[string, string]()
  defaultsUA["client"] = defUserAgent
  defaultsUA["nim"] = "Nim/0.17.0"
  defaultsUA["system"] = hostOS & "/"

  if len(customAgent) > 0:
    customAgentSeq.add(customAgent)

  result = SlackRequest(proxy: proxy, defaultUserAgent: defaultsUA, customUserAgent: customAgentSeq)

proc getUserAgent*(self: SlackRequest): string = 

  if len(self.customUserAgent) > 0:
    var customUaList = newSeq[string](0)
    for uaString in self.customUserAgent:
      customUaList.add(uaString)
    let customUaString = join(customUaList, " " )
    self.defaultUserAgent["custom"] = customUaString

  var uaString = newSeq[string](0)
  for ua in values(self.defaultUserAgent):
    uaString.add(ua)

  result = join(uaString, " ")

proc appendUserAgent(self: SlackRequest, name: string, version: string): int {.discardable.} = 
  if len(self.customUserAgent) > 0:
    self.customUserAgent.add(replace(name, "/", ":") & " " & replace(version, "/", ":"))

proc sendRequest*(self: SlackRequest, token: string, request = "?", data: JsonNode, domain = "slack.com", timeout: int): Response {.discardable.} =
  ## Send a request to the slack api
  ## We add all elements from our json data node passed in and 
  ## send it up with a token
  var client = newHttpClient()

  let url = "https://" & domain & "/api/" & request
  client.headers = newHttpHeaders({
      "user-agent": getUserAgent(self),
      "Content-Type": "application/json; charset=utf-8"
    })
  var postBody = %*
    {
      "token": token,
    }
  
  for key, value in data.pairs:
    postBody[key] = value

  result = client.request(url, httpMethod = HttpPost, body = $postBody)
