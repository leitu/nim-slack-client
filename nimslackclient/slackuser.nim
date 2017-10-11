from lists import SinglyLinkedList
from slacktypes import SlackUser, SlackServer, TimeZone

proc initSlackUser*(user_id: string, name: string, real_name: string, email: string, timezone: TimeZone = TimeZone(zone: "UTC"), server: SlackServer): SlackUser = 
  ## Create and return a user
  result = SlackUser(id: user_id, name: name, real_name: real_name, email: email, timezone: timezone, server: server)

proc initSlackUser*(user_id: string, name: string, real_name: string = "", email: string = "", timezone: string = "UTC", server: SlackServer): SlackUser = 
  ## handles tz as string
  let tz = TimeZone(zone: timezone)
  result = initSlackUser(user_id = user_id, name = name, real_name = real_name, email = email, timezone = tz, server = server)
