# Package

version = "0.1.0"
author = "TangDongle"
description = "Basic socket stuff with nim"
license = "MIT"

requires "nim >= 0.17.0"

task co, "Compile":
  exec "nim c -d:ssl --threads:on test.nim"
