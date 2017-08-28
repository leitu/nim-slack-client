include types

proc initUser(name: string, real_name: string, timezone: TimeZone): User = 
  ## Create and return a user
  result = User(name = name, real_name = real_name, timezone = timezone, server = server)

proc initUser(name: string, real_name: string, timezone: string): User = 
  ## handles tz as string
  let tz = TimeZone(zone = timezone)
  result = User(name = name, real_name = real_name, timezone = tz, server = server)

