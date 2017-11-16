from slacktypes import SlackChannel, SlackServer, SlackUser

proc initSlackChannel*(channel_id: string, name: string = "", members: seq[SlackUser] = newSeq[SlackUser](0), server: SlackServer): SlackChannel = 
  ## Create and return a user
  new result
  result.id = channel_id
  result.name = name
  result.channel_members = members
  result.server = server

