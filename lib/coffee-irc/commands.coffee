# data on how to format each command

_ = require('underscore')

# commands that use a ':trailing argument'
trailingCommands = [
  'USER',
  'QUIT',
  'PRIVMSG',
  'NOTICE',
  'INVITE',
  'TOPIC',
  'KICK',
]

# commands that do not use the trailing argument
nonTrailingCommands = [
  'NICK',
  'PASS',
  'JOIN',
  'PART',
  'NICKSERV IDENTIFY',
  'MODE',
  'LIST',
]

ctcpCommands = [
 'ACTION'
]

commands = {}

for cmd in trailingCommands
  do (cmd) ->
    (commands[cmd] ?= {}).style = 'trailing'

for cmd in nonTrailingCommands
  do (cmd) ->
    (commands[cmd] ?= {}).style = 'plain'

for cmd in ctcpCommands
  do (cmd) ->
    (commands[cmd] ?= {}).style = 'ctcp'

module.exports = commands

