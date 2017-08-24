import json, httpclient

type
  SlackRequest* = ref object of RootObj
    defaultUserAgent: string
    customUserAgent: string
    proxies: Proxy


