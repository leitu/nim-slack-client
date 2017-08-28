const msgArm = slackMsg("#bottystuff", "Alarms is turned on", "good", "Alarm Update", "The controller has been turned on")

proc slackServerRun*(slackReq: asynchttpserver.Request) {.async.} =
  # To change the standard port:
  slackPort = Port(3000)

  # Case the command
  case slackEvent(slackReq, "command"):
  of "/arm": 
    # If you need to run a proc with the arguments sent, access the 'text' field:
    echo slackEvent(slackReq, "text")
    await slackRespond(slackReq, msgArm))

  of "/disarm":
    echo "DISARMED"
    await slackRespond(slackReq, slackMsg("#bottystuff", "nimslack", "DISARMED", "", "good", "Alarm Update", "The alarm has been disarmed"))

  else:
    await slackRespond(slackReq, slackMsg("#bottystuff", "nimslack", "ERROR", "", "danget", "Alarm Update", "That command is not part of me"))  

waitFor slackServer.serve(slackPort, slackServerRun)
