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
    loginData: JsonNode
    users: SinglyLinkedList[SlackUser]
    channels: SinglyLinkedList[SlackChannel]

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

type
  SlackRequest* = ref object of RootObj
    defaultUserAgent*: Table[string, string]
    customUserAgent*: seq[string]
    proxy*: Proxy

