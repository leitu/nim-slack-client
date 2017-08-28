from slacktypes import SlackUser, SlackServer

proc initSlackUser*(user_id: string, name: string, real_name: string, timezone: TimeZone, server: SlackServer): SlackUser = 
  ## Create and return a user
  result = SlackUser(name = name, real_name = real_name, timezone = timezone, server = server)

proc initSlackUser*(user_id: string, name: string, real_name: string, timezone: string, server: SlackServer): SlackUser = 
  ## handles tz as string
  let tz = TimeZone(zone = timezone)
  result = SlackUser(name = name, real_name = real_name, timezone = tz, server = server)


