# eventually this will become a full-fledged object with convenience methods, etc

_ = require('underscore')

replyFor = require('./replyFor')

# the prefix may be like:
# 
#   NickServ!NickServ@services.
#
#   nobotjs!~nobotjs@pool-1-2-3-4.nycmny.fios.verizon.net
#

PREFIX_RE = ///

  ^([_a-zA-Z0-9\[\]\\`^{}|-]*)  # server/nickname parser (before the !)
  (!                            # swallow the !
    ([^@]+)                     # the user
    @                           # swallow the @
    (.*)                        # take the rest (host + other)
  )?                            # maybe this isn't from a user?
  $                             # ah, here's the EOL!

///

class Message
  constructor: (@client, @opt) ->
    @client ?= null
    @opt ?= {}
    @prefix = @server = @rawCommand = @command = @commandType = @nick = @user = null
    @args = []


module.exports.parse = (line) ->
  message = new Message()
  match = null

  # parse prefix
  if match = line.match(/^:([^ ]+) +/)
    message.prefix = match[1]
    line = line.replace(/^:[^ ]+ +/, '')

    if match = message.prefix.match(PREFIX_RE)
      [x, message.nick, x, message.user, message.host] = match
    else
      message.server = message.prefix

  # parse command
  match = line.match(/^([^ ]+) +/)
  message.command = message.rawCommand = match[1]
  message.commandType = 'normal'
  line = line.replace(/^[^ ]+ +/, '')

  if rf = replyFor[message.rawCommand]
    message.command = rf.name
    message.commandType = rf.type

  middle = trailing = null
  idx = line.indexOf(':')

  if (idx > -1)
    middle = line.substr(0, idx).replace(/[ ]+$/, "")
    trailing = line.substr(idx+1)
  else
    middle = line

  if middle.length
    message.args = middle.split(/[ ]+/)

  unless _(trailing).isNull()
    message.args.push(trailing) if trailing.length

  return message


