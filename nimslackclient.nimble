# Package

version = "0.1.0"
author = "TangDongle"
description = "Basic socket stuff with nim"
license = "MIT"

requires "nim >= 0.17.0"
requires "https://github.com/Tangdongle/websocket.nim"

task co, "Compile":
  exec "nim c -d:ssl nimslackclient.nim"

task run, "Run":
  exec "mkdir -p bin"
  exec "nim c -r -d:ssl --out:bin/nimslackclient nimslackclient.nim"

task watch, "Watch":
  exec "while inotifywait -r -e close_write .; do nimble run; done"  
