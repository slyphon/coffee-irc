# See LICENSE file for details

# for testing purposes
require = GENTLY.hijack(require) if global.GENTLY

sys = require('sys')
net = require('net')
tls = require('tls')
_ = require('underscore')

replyFor = require('./replyFor')

{EventEmitter} = require('events')
{InvalidConfigError} = require('./errors')

UTF8 = 'utf8'
CRLF = "\r\n"

class Client extends EventEmitter
  @defaultOpts:
    password: null
    userName: 'coffee-irc'
    realName: 'coffee-irc client'
    secure: false
    port: 6667
    debug: false
    showErrors: false
    autoRejoin: true
    autoConnect: true
    channels: null
    retryLimit: null
    retryDelay: 2000
    secure: false

  constructor: (server, nick, @opt={}) ->
    _.defaults(@opt, @defaultOpts)

    # according to RFC2812
    nick = nick.substr(0,9) if nick.length > 9

    _(@opt).extend
      server: server
      nick: nick

    @opt.channels ?= []
    @conn = null
    @chans = {}
    @buffer = ''
    @retryCount = 0
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
    
  send: (args..., last) ->
    req = "#{args.join(' ')} :#{last}"
    @_debug "SEND: #{req}"
    @conn.write([req, CRLF].join(''))

  join: (channel, callback) ->
    @once('join' + channel, callback) if _(callback).isFunction()
    @send('JOIN', channel)
  
  part: (channel, callback) ->
    @once('part' + channel, callback) if _(callback).isFunction()
    @send('PART', channel)

  say: (target, text):
    @send('PRIVMSG', target, text)

  _createSecureConnection: () ->
    creds =
      if (typeof @opt.secure !== 'object') then {} else @opt.secure
    
    @conn = tls.connect @opt.port, @opt.server, creds, () =>
      @conn.connected = true

      if @conn.authorized
        @_handleConnConnect()
      else
        console.log(@conn.authorizationError)
        @emit('connect', @conn.authorizationError)

  _createConnection: () ->
    {port, server} = @opt
    @conn = net.createConnection(port, server)

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
        message = @parseMessage(line)
        try
          self.emit('raw', message)
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
    setTimeout @connect, @opt.retryDelay


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
    console.log(message)

module.exports = Client


