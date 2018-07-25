# nim slack client *WIP*

Wrapper for Slack's RTM API

## Doc sources

https://api.slack.com/rtm
https://api.slack.com/web#authentication

## Going Forward

* Handle file sending
* Handle profiles
* Make some default handlers for common messages


=======

# Nim Slack Client

## Introduction

Provides a nim wrapper to Slack's Real Time Messaging API

A slack bot token is required to access the API

## This is echo slack bot

This Bot is based on latest nim devel version. you may need to update nim.

```bash
$ nimble run
or
$ mkdir -p bin
$ nim c -r -d:ssl --out:bin/nimslackclient nimslackclient.nim
```
