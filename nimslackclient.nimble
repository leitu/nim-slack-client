# Package

version = "0.1.1"
author = "TangDongle"
description = "Slack Client API for nim"
license = "MIT"

requires "nim >= 0.17.0"
requires "https://github.com/Tangdongle/websocket.nim#head"

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
