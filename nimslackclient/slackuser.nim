from lists import SinglyLinkedList
from slacktypes import SlackUser, SlackServer

proc initSlackUser*(user_id: int, name: string, real_name: string = "", email: string = "", timezone: TimeZone = TimeZone(zone: ""), server: SlackServer = nil): SlackUser = 
  ## Create and return a user
  result = SlackUser(id: user_id, name: name, real_name: real_name, email: email, timezone: timezone, server: server)

proc initSlackUser*(user_id: int, name: string, real_name: string = "", email: string = "", timezone: string = "", server: SlackServer = nil): SlackUser = 
  ## handles tz as string
  let tz = TimeZone(zone: timezone)
  result = SlackUser(id: user_id, name: name, real_name: real_name, email: email, timezone: tz)
