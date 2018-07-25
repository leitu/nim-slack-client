# Package

version = "0.1.2"
author = "TangDongle, Alex"
description = "Slack Client API for nim"
license = "MIT"

requires "nim >= 0.18.1"
requires "websocket >= 0.3.1", "https://github.com/superfunc/maybe"

task co, "Compile":
  exec "nim c -d:ssl --out:bin/nimslackclient nimslackclient.nim"

task run, "Run":
  exec "mkdir -p bin"
  exec "nim c -r -d:ssl --out:bin/nimslackclient nimslackclient.nim"

task release, "Release":
  exec "mkdir -p bin"
  exec "nim c -d:release -d:ssl --out:bin/nimslackclient nimslackclient.nim"

task watch, "Watch":
  exec "while inotifywait -r -e close_write .; do nimble run; done"  

task debug, "Debug":
  exec "mkdir -p bin"
  exec "nim c --debugger:native -d:ssl --out:bin/nimslackclient nimslackclient.nim"

task ch, "Check Syntax":
  exec "nim check -d:ssl nimslackclient.nim"
  for fn in listFiles("nimslackclient"):
    echo fn
    exec "nim check -d:ssl " & fn
