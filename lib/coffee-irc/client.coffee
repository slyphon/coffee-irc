# See LICENSE file for details

sys = require('sys')
net = require('net')
tls = require('tls')
events = require('events')
_ = require('underscore')

replyFor = require('./replyFor')
{InvalidConfigError} = require('./errors')


class Client extends events.EventEmitter
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

    _.extend @opt,
      server: server
      nick: nick

    @opt.channels = [] unless @opt.channels
    @conn = null
    this._validateConfig()


  _validateConfig: () ->
    unless _.isString(@opt.nick)
      throw new InvalidConfigError("You must specify a nick")

    if @opt.nick.indexOf(' ') >= 0
      throw new InvalidConfigError("Nicknames should not contain spaces: '#{@opt.nick}'")

    unless _.isString(@opt.server)
      throw new InvalidConfigError("You must specify a server")



module.exports = Client


