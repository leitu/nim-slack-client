# Package

version = "0.1.0"
author = "TangDongle"
description = "Basic socket stuff with nim"
license = "MIT"

requires "nim >= 0.17.0"
requires "websocket >= 0.2.1"

task co, "Compile":
  exec "nim c -d:ssl nimslackclient.nim"

task run, "Run":
  exec "mkdir -p bin"
  exec "nim c -r -d:ssl --out:bin/nimslackclient nimslackclient.nim"
