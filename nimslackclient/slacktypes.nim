import uri
import json, tables
import httpclient
from lists import SinglyLinkedList
import websocket
from events import EventEmitter, EventArgs

type
  TimeZone* = ref object of RootObj
    zone: string

type
  SlackServer* = ref SlackServerObj
  SlackServerObj = object of RootObj
    token: string
    username: string
    domain: string
    websocket: AsyncWebSocket
    loginData: JsonNode
    users: SinglyLinkedList[SlackUser]
    channels: SinglyLinkedList[SlackChannel]
    connected: bool
    wsUrl: Uri
    config: Config
    proxies: seq[Proxy]
    apiRequester: SlackRequest

  SlackUser* = ref SlackUserObj
  SlackUserObj = object of RootObj
    id: string
    name: string
    real_name: string
    email: string
    server: SlackServer
    timezone: TimeZone

  SlackChannel* = ref SlackChannelObj
  SlackChannelObj = object of RootObj 
    id: string 
    name: string
    server: SlackServer
    channel_members: seq[SlackUser]

  Config* = object
    WsPort*: string
    BotName*: string
    BotEmail*: string
    BotTimeZone*: string #Must be a valid tz, ie "Australia/Sydney" https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
    BotToken*: string

  SlackMessage* = ref SlackMessageObj
  SlackMessageObj = object of RootObj
    Type*: string
    Channel*: SlackChannel
    User*: SlackUser
    Text*: string
    TimeStamp*: string

  SlackClientObj = object of RootObj
    Server*: SlackServer
    Token*: string

  SlackClient* = ref SlackClientObj

  SlackRequest* = ref object of RootObj
    defaultUserAgent*: Table[string, string]
    customUserAgent*: seq[string]
    proxies*: seq[Proxy]

proc `$`*(C: SlackChannel): string = 
  return C.name

proc `$`*(C: SlackUser): string = 
  return C.name

proc `$`*(C: SlackMessage): string = 
  return "Type: " & C.Type & ", Channel: " & $C.Channel & ", User: " & $C.User & ", TimeStamp: " & C.TimeStamp
