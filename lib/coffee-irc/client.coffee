# See LICENSE file for details

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
    this._validateConfig()

  connect: () =>
    if @opt.secure
      this._createSecureConnection()
    else
      this._createConnection()

    @conn.requestedDisconnect = false
    @conn.setTimeout(0)
    @conn.setEncoding(UTF8)
    @conn.addListener 'connect', this._handleConnConnect
    @conn.addListener 'data', this._handleConnData
    @conn.addListener 'end', this._handleConnEnd

  disconnect: (message=null) ->
    message ?= "coffee-irc says goodbye"

    this.send('QUIT', message) if @conn.readyState == 'open'

    @conn.requestedDisconnect = true
    @conn.end()
    
  send: (args..., last) ->
    req = "#{args.join(' ')} :#{last}"
    this._debug "SEND: #{req}"
    @conn.write([req, CRLF].join(''))

  join: (channel, callback) ->
    this.once('join' + channel, callback) if _(callback).isFunction()
    this.send('JOIN', channel)
  
  part: (channel, callback) ->
    this.once('part' + channel, callback) if _(callback).isFunction()
    this.send('PART', channel)

  say: (target, text):
    this.send('PRIVMSG', target, text)

  _createSecureConnection: () ->
    creds =
      if (typeof @opt.secure !== 'object') then {} else @opt.secure
    
    @conn = tls.connect @opt.port, @opt.server, creds, () =>
      @conn.connected = true

      if @conn.authorized
        this._handleConnConnect()
      else
        console.log(@conn.authorizationError)
        # XXX: uhh, *THEN* what?

  _createConnection: () ->
    {port, server} = @opt
    @conn = net.createConnection(port, server)

  # called by our code after either a connection event is received or 
  # our TLS connection is authorized
  _handleConnConnect: () =>
    {password,nick,userName,realName} = @opt
    @conn.setEncoding(UTF8)

    unless _(password).isNull()
      this.send('PASS', password)

    console.log("sending irc NICK/USER")
    this.send('NICK', nick)
    @nick = nick
    this.send('USER', userName, 8, '*', realName)
    this.emit('connect')

  _handleConnData: (chunk) =>
    # use a persistent buffer
    @buffer += chunk
    lines = @buffer.split("\r\n")
    @buffer = lines.pop()
    for line in lines
      do (line) ->
        message = this.parseMessage(line)
        try
          self.emit('raw', message)
        catch err
          throw err if !@conn.requestedDisconnect

  _handleConnEnd: () =>
    return if @conn.requestedDisconnect
      
    this._debug("Disconnected: reconnecting")

    if !_(@opt.retryLimit).isNull() && @retryCount >= @opt.retryLimit
      this._debug("maxiumum retry count (#{@retryCount}) reached, aborting")
      this.emit("abort", @opt.retryLimit)
      return

    this._debug("waiting for #{@opt.retryDelay} ms before retrying")

    @retryCount += 1
    setTimeout this.connect, @opt.retryDelay


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


