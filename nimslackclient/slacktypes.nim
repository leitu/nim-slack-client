import uri
import json, tables
import httpclient
from lists import SinglyLinkedList
import websocket

type
  TimeZone* = ref object of RootObj
    zone: string

type
  SlackServer* = ref object of RootObj
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

  SlackUser* = ref object of RootObj
    id: string
    name: string
    real_name: string
    email: string
    server: SlackServer
    timezone: TimeZone

  SlackChannel* = ref object of RootObj 
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


type
  SlackRequest* = ref object of RootObj
    defaultUserAgent*: Table[string, string]
    customUserAgent*: seq[string]
    proxy*: Proxy

