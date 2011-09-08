# See LICENSE file for details

sys = require('sys')
net = require('net')
tls = require('tls')
_ = require('underscore')

replyFor = require('./replyFor')

{EventEmitter} = require('events')
{InvalidConfigError} = require('./errors')


UTF8 = 'utf8'

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
    retryCount: null
    retryDelay: 2000
    secure: false

  constructor: (server, nick, @opt={}) ->
    _.defaults(@opt, @defaultOpts)

    # according to RFC2812
    nick = nick.substr(0,9) if nick.length > 9

    _(@opt).extend
      server: server
      nick: nick

    @opt.channels = [] unless @opt.channels
    @conn = null
    @buffer = ''
    this._validateConfig()

  connect: (retryCount=0) =>
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
    @buffer += chunk

  _handleConnEnd: () =>

  _validateConfig: () ->
    {nick,server} = @opt

    unless _(nick).isString()
      throw new InvalidConfigError("You must specify a nick")

    if nick.indexOf(' ') >= 0
      throw new InvalidConfigError("Nicknames should not contain spaces: '#{nick}'")

    unless _(server).isString()
      throw new InvalidConfigError("You must specify a server")


module.exports = Client


