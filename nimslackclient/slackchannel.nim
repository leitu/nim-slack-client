
type
  SlackChannel* = ref object of RootObj
    name: string
    real_name: string
    id: int
    timezone: TimeZone
