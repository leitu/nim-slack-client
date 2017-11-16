import nre
import json
import lists
from slacktypes import SlackChannel, SlackServer, SlackUser, SlackMessage
from httpclient import Response

proc `Type=`*(self: var SlackMessage, data: string) {.inline.} = 
  self.Type = data

proc `Channel=`*(self: var SlackMessage, data: SlackChannel) {.inline.} =
  self.Channel = data

proc `Channel=`*(self: var SlackMessage, data: SlackUser) {.inline.} =
  self.User = data

proc `Text=`*(self: var SlackMessage, data: string) {.inline.} =
  self.Text = data

proc `TimeStamp=`*(self: var SlackMessage, data: string) {.inline.} =
  self.TimeStamp = data

proc buildSlackMessage*(server: SlackServer, data: JsonNode, response: Response = Response()): SlackMessage = 
  let MESSAGETEXT = re"^<@\w*?> (.*)"

  new(result)

  var isMessage = false
  var acceptedType = "message"

  result.Type = data["type"].getStr("")
  if result.Type == acceptedType:
    isMessage = true
    echo "Is message type!"

  if isMessage:
    echo "MESSAGE!"

  if data.hasKey("text"):
    if data["text"].str.contains(MESSAGETEXT):
      result.Text = data["text"].str.match(MESSAGETEXT).get.captures[0]

  if data.hasKey("ts"):
    result.TimeStamp = data["ts"].str
    
  var hasMatch = false
  if data.hasKey("user"):
    if isMessage:
      echo "User data " & data["user"].str
    for u in items(server.users):
      if isMessage:
        echo "User iter " & u.id
      if u.id == data["user"].str:
        hasMatch = true
        result.User = u
        echo "Breaking, found user " & result.User.name
        break

  if data.hasKey("channel"):
    for c in server.channels.items():
      if c.id == data["channel"].str:
        result.Channel = c
        break

  result.Response = response

