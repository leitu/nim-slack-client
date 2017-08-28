import json, tables
import httpclient
from lists import SinglyLinkedList

type
  TimeZone* = ref object of RootObj
    zone: string

type
  SlackServer* = ref object of RootObj
    token: string
    username: string
    domain: string
    websocket: asyncWebsocket
    loginData: JsonNode
    users: SinglyLinkedList[SlackUser]
    channels: SinglyLinkedList[SlackChannel]
    connected: false
    wsUrl: string
    

  SlackUser* = ref object of RootObj
    id: int
    name: string
    real_name: string
    server: SlackServer
    timezone: TimeZone

  SlackChannel* = ref object of RootObj 
    id: int
    name: string
    server: SlackServer
    real_name: string
    members: seq[User]

type
  SlackRequest* = ref object of RootObj
    defaultUserAgent*: Table[string, string]
    customUserAgent*: seq[string]
    proxy*: Proxy

