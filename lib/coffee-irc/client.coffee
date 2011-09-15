# See LICENSE file for details

sys = require('sys')
_ = require('underscore')

commands = require('./commands')
replyFor = require('./replyFor')
message  = require('./message')

{EventEmitter2} = require('eventemitter2')

{InvalidConfigError,
 UnrecognizedCommandError,
 ArgumentError} = require('./errors')

UTF8 = 'utf8'
CRLF = "\r\n"

class Mode
  constructor: ->
    @flags = {}
    
  update: (modeStr) ->
    _i = sys.inspect

    unless _(modeStr).isString()
      throw new ArgumentError("argument to update must be a string, not: #{_i(modeStr)}")

    oper = modeStr[0]

    unless (oper is '-') or (oper is '+')
      throw new ArgumentError("Invalid mode string: #{_i(modeStr)}")

    for f in modeStr[1..-1]
      do (f) ->
        @flags[f] = (oper is '+')

  toString: () ->
    a = ['+']

    for k in _(@flags).keys()
      do (k) ->
        a.push(k) if @flags[k]

    a.join('')


class Channel
  constructor: (@name) -> {}



# The base Client prototype. When messages are received from the server
# they will be dispatched via a namespaced event on the client instance
#
class Client extends EventEmitter2
  # this allows these modules to be stubbed out in tests,
  # gross but apparently necessary :/
  @net = require('net')
  @tls = require('tls')

  @defaultOpts:
    password: null
    userName: 'coffee-irc'
    realName: 'coffee-irc client'
    secure: false
    port: 6667
    debug: true
    showErrors: false
    autoRejoin: true
    autoConnect: true
    channels: null
    retryLimit: null
    retryDelay: 2000
    secure: false

  @emitterOpts:
    wildcard: true
    delimiter: '.'
    maxListeners: 500

  # these functions will be bound to the client as handlers
  # at construction time. they are defined here to give users
  # of this client a chance to modify them before construction
  @protocolHandlers:
    rpl_welcome: (msg) ->
      @emit('registered')

    err_nicknameinuse: (msg) ->
      @nickTryCount++
      @nick = "#{@nick}_"
      @send('NICK', @nick)

    ping: (msg) ->
      @send('PONG', msg.args[0])

    notice: (msg) ->
      [from, to, text] = [msg.nick, msg.args[0], msg.args[1]]
      to ?= null
      @_debug("NOTICE from: #{if from? then from else 'the server'}: '#{text}'")
      @emit('notice', from, to, text)

    mode: (msg) ->
      [who, mode] = msg.args[0..1]
      @_debug("MODE: #{who} mode: #{mode}")

        
  constructor: (server, nick, @opt) ->
    # set up EventEmitter2
    super(Client.emitterOpts)

    @opt ?= {}
    _(@opt).defaults(Client.defaultOpts)

    # according to RFC2812
    # XXX: get rid of this, it's dumb
    nick = nick.substr(0,9) if nick.length > 9

    _(@opt).extend
      server: server
      nick: nick

    @opt.channels ?= []
    @conn = null
    @chans = {}
    @buffer = ''
    @retryCount = 0
    @nickTryCount = 0
    @_validateConfig()

  # if a callback is passed, it will be called with an error if an exception occurs
  # or no arguments upon connection
  connect: (callback) =>
    @once('connect', callback) if _(callback).isFunction()

    if @opt.secure
      @_createSecureConnection()
    else
      @_createConnection()

    @conn.requestedDisconnect = false
    @conn.setTimeout(0)
    @conn.setEncoding(UTF8)
    @conn.addListener 'connect', @_handleConnConnect
    @conn.addListener 'data', @_handleConnData
    @conn.addListener 'end', @_handleConnEnd

  disconnect: (message=null) ->
    message ?= "coffee-irc says goodbye"

    @send('QUIT', message) if @conn.readyState == 'open'

    @conn.requestedDisconnect = true
    @conn.end()
    
  send: (command, args...) ->
    cmd = commands[command]

    unless cmd
      i = sys.inspect
      throw new UnrecognizedCommandError "unknown command #{i(command)}, args: #{i(args)}"

    if cmd.style is 'trailing'
      last = args.pop()
      args.push(":#{last}")

    req = "#{command} #{args.join(' ')}"

    @_debug "SEND: #{req}"
    @conn.write([req, CRLF].join(''))

  join: (channel, callback) ->
    @once('join' + channel, callback) if _(callback).isFunction()
    @send('JOIN', channel)
  
  part: (channel, callback) ->
    @once('part' + channel, callback) if _(callback).isFunction()
    @send('PART', channel)

  say: (target, text) ->
    @send('PRIVMSG', target, text)

  _messageReceived: (line) ->
    message = @_parseMessage(line)
    @emit(['raw', message.command], message)

  _createSecureConnection: () ->
    creds =
      if (typeof(@opt.secure) != 'object') then {} else @opt.secure
    
    @conn = Client.tls.connect @opt.port, @opt.server, creds, () =>
      @conn.connected = true

      if @conn.authorized
        @_handleConnConnect()
      else
        console.log(@conn.authorizationError)
        @emit('connect', @conn.authorizationError)

  _createConnection: () ->
    {port, server} = @opt
    @conn = Client.net.createConnection(server, port)

  # called by our code after either a connection event is received or 
  # our TLS connection is authorized
  _handleConnConnect: () =>
    {password,nick,userName,realName} = @opt
    @conn.setEncoding(UTF8)

    unless _(password).isNull()
      @send('PASS', password)

    console.log("sending irc NICK/USER")
    @send('NICK', nick)
    @nick = nick
    @send('USER', userName, 8, '*', realName)
    @emit('connect')

  _handleConnData: (chunk) =>
    # use a persistent buffer
    @buffer += chunk
    lines = @buffer.split("\r\n")
    @buffer = lines.pop()
    for line in lines
      do (line) ->
        try
          @_messageReceived(line)
        catch err
          throw err if !@conn.requestedDisconnect

  _handleConnEnd: () =>
    return if @conn.requestedDisconnect
      
    @_debug("Disconnected: reconnecting")

    if !_(@opt.retryLimit).isNull() && @retryCount >= @opt.retryLimit
      msg = "maxiumum retry count (#{@retryCount}) reached, aborting"
      @_debug(msg)
      @emit('', msg)
      return

    @_debug("waiting for #{@opt.retryDelay} ms before retrying")

    @retryCount += 1
    setTimeout(@connect, @opt.retryDelay)


  _validateConfig: () ->
    {nick,server} = @opt

    unless _(nick).isString()
      throw new InvalidConfigError("You must specify a nick")

    if nick.indexOf(' ') >= 0
      throw new InvalidConfigError("Nicknames should not contain spaces: '#{nick}'")

    unless _(server).isString()
      throw new InvalidConfigError("You must specify a server")

  _debug: (message) =>
    return unless @opt.debug
    sys.log(message)

  _parseMessage: (line) ->
    # possibly do other processing here
   message.parse(line)


module.exports =
  Client: Client
  Mode: Mode
  Channel: Channel


