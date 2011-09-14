# eventually this will become a full-fledged object with convenience methods, etc

_ = require('underscore')
sys = require('sys')

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

CHANNEL_RE = /^[#$&]/

DEFAULT_COMMAND_TYPE = 'normal'

Mixins =
  # should be called Mixin.extend(PrivmsgMixin, messageInstance)
  extend: (mixin, message) ->
    _(message).extend(mixin.defaultProperties)
    _(message).extend(mixin.instanceMethods)
    return message

# PRIVMSGs have the following properties:
#   - they are either to a channel or to a specific user (a 'private message')
#   - if they are addressing a particular user in a channel, they follow the format 'addressee: rest of message'
#
# this further parses the message and adds the following
#
# if the message is to a channel (i.e. the first argument begins with [#$&])
#   - the channel property will be set
#   - the message will be parsed and the addressee property will contain the name of the person
#     being addressed in the channel, or null if the message is just to the channel at large
#
# if the message is to us only
#   - the channel property will be null
#   - the addressee will contain our nick
#
# in either case the isToUs() will return true if it is we who are being
# addressed (based on the @client.nick property) in a channel. Will always
# return true if isPrivate() is true.
#
# isPublic() will return true if the message was sent *to* a channel (but may
# be addressing someone else)
#
# the text property will contain the full text of the message (including addressee)
#
PrivmsgMixin =
  defaultProperties:
    channel: null
    addressee: null

  instanceMethods:
    isPrivmsg: -> true

    # was the message to a channel?
    isPublic: -> @channel?

    # was the message to us?
    isToUs: ->
      @client? and (@client.nick is @addressee)

  # parses the addressee out of the message and returns it, or null if the message isn't 
  # addressed to anyone in particular
  parseAddressee: (str) ->
    return null unless _(str).isString()
    if m = str.match(/^([^:]+):/) then m[1] else null

  # used to modify the message state when this is mixed in
  extend: (msg) ->
    Mixins.extend(this, msg)

    [recip, msg.text] = msg.args

    if recip?
      if recip.match(CHANNEL_RE)
        msg.channel = recip
        msg.addressee = PrivmsgMixin.parseAddressee(msg.text)
      else
        msg.addressee = recip

    return msg


# A parsed IRC message.
#
class Message
  constructor: (line, @client = null, @opt = {}) ->
    @prefix = @server = @rawCommand = @command = @nick = @user = null
    @args = []
    unless _(line).isUndefined()
      @_parse(line)
      @_extend()

  _parse: (line) ->
    match = null

    # parse prefix
    if match = line.match(/^:([^ ]+) +/)
      @prefix = match[1]
      line = line.replace(/^:[^ ]+ +/, '')

      if match = @prefix.match(PREFIX_RE)
        [x, @nick, x, @user, @host] = match
      else
        @server = @prefix

    # parse command
    match = line.match(/^([^ ]+) +/)
    @command = @rawCommand = match[1]
    @commandType = DEFAULT_COMMAND_TYPE

    line = line.replace(/^[^ ]+ +/, '')

    if rf = replyFor[@rawCommand]
      @command = rf.name
      @commandType = rf.type

    middle = trailing = null
    idx = line.indexOf(':')

    if (idx > -1)
      middle = line.substr(0, idx).replace(/[ ]+$/, "")
      trailing = line.substr(idx+1)
    else
      middle = line

    if middle.length
      @args = middle.split(/[ ]+/)

    unless _(trailing).isNull()
      @args.push(trailing) if trailing.length

  _extend: ->
    switch @command
      when 'PRIVMSG' then PrivmsgMixin.extend(this)


module.exports.parse = (args...) ->
  new Message(args...)

module.exports.Message = Message

