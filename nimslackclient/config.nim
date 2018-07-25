## Config module by Ashley Broughton
from slacktypes import Config
import os
import tables
import json
import strutils
import logging
from os import getEnv

const config_file_name = "config.json"
let config_dir = joinPath(getConfigDir(), "nimslackclient")
let config_file_path = joinPath(config_dir, config_file_name)


proc defaultConfig(): Config =
  result.WsPort = "443"
  result.BotName = "lt"
  result.BotEmail = "test@gmail.com"
  result.BotTimeZone= "UTC"
  result.BotToken = ""

proc configToJsonString(config: Config): string =
  var t = initOrderedTable[string, JsonNode]()
  t.add("WsPort", newJString(config.WsPort))
  t.add("BotName", newJString(config.BotName))
  t.add("BotEmail", newJString($config.BotEmail))
  t.add("BotTimeZone", newJString($config.BotTimeZone))
  t.add("BotToken", newJString($config.BotToken))

  var jobj = newJObject()
  jobj.fields = t

  result = pretty(jobj) & "\n"

proc readConfig(): Config =
  var json_node: JsonNode
  json_node = parseFile(config_file_path)
  result.WsPort = json_node["WsPort"].str
  result.BotName = json_node["BotName"].str
  result.BotEmail = json_node["BotEmail"].str
  result.BotToken = json_node["BotToken"].str

proc loadConfig*(): Config =
  let first_run = not existsOrCreatedir(config_dir)
  let config_exists = existsFile(config_file_path)
  
  if first_run or not config_exists:
    writeFile(config_file_path, configToJsonString(defaultConfig()))

  try:
    result = readConfig()
  except:
    echo("Failed to read config file from: " & config_file_path)
    raise

proc slackConfigFilePath*(): string = 
  return config_file_path

proc getSlackBotToken*(self: Config): string = 
  ## Returns our slack bot token
  var token = ""
  if (self.BotToken.len == 0):
    token = string(getEnv("SLACK_BOT_TOKEN"))
    echo token
    if (token.len == 0):
      echo "No Bot Token set in config and no SLACK_BOT_TOKEN environment variable"
      quit(1)
  else:
    token = self.BotToken
  return token
