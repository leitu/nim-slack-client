from slacktypes import SlackChannel, SlackServer, SlackUser

proc initSlackChannel*(channel_id: string, name: string, members: seq[SlackUser], timezone: TimeZone, server: SlackServer): SlackUser = 
  ## Create and return a user
  result = SlackUser(name = name, real_name = real_name, timezone = timezone, server = server)

