from slacktypes import SlackChannel, SlackServer, SlackUser

proc initSlackChannel*(channel_id: string, name: string, members: seq[SlackUser] = newSeq[SlackUser](0), server: SlackServer): SlackChannel = 
  ## Create and return a user
  result = Slackchannel(id: channel_id, name: name, channel_members: members, server: server)

