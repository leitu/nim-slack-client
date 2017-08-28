import httpclient, websocket, json

proc initRTM*(request: SlackRequest, domain = "slack.com", token: string): string = 
  ## Make an initial connection to slack and return a success string or failure string
  ##
  var data = newMultiPartData()

  var client = newHttpClient()

  let url = "https://" & domain & "/api/rtm.start"
  client.headers = newHttpHeaders({
      "user-agent": getUserAgent(request),
      "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
    })

  data["token"] = token
  
  return client.postContent(url, multipart = data)

proc didInitSucceed(response: string): bool = 
  return true
