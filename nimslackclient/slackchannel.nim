from slacktypes import SlackChannel, SlackServer, SlackUser
import lists

proc initSlackChannel*(channel_id: string, name: string = "", members: seq[SlackUser] = newSeq[SlackUser](0), server: SlackServer): SlackChannel = 
  ## Create and return a user
  new result
  result.id = channel_id
  result.name = name
  result.channel_members = members
  result.server = server

proc findChannelById*(channel_id: string, server: SlackServer): SlackChannel =
  #[
  # Return a SlackChannel by ID or nil
  ]#
  for channel in server.channels:
    if channel.id == channel_id:
      return channel
  return nil
  
