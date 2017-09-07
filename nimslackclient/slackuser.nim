from lists import SinglyLinkedList
from slacktypes import SlackUser, SlackServer

proc initSlackUser*(user_id: string, name: string, real_name: string = "", timezone: TimeZone = TimeZone(zone: "")): SlackUser = 
  ## Create and return a user
  result = SlackUser(name : name, real_name : real_name, timezone : timezone)

proc initSlackUser*(user_id: string, name: string, real_name: string = "", timezone: string = ""): SlackUser = 
  ## handles tz as string
  let tz = TimeZone(zone: timezone)
  result = SlackUser(name : name, real_name : real_name, timezone : tz)

proc initSlackUserList*(): SinglyLinkedList = 
  result = SinglyLinkedList()


