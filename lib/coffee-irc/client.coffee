# See LICENSE file for details

sys = require('sys')
net = require('net')
tls = require('tls')
events = require('events')
_ = require('underscore')

replyFor = require('./replyFor')

class Client extends events.EventEmitter
  self = this

  @createDefaults: ->
    password: null
    userName: 'coffee-irc'
    realName: 'coffee-irc client'
    secure: false
    port: 6667
    debug: false
    showErrors: false
    autoRejoin: true
    autoConnect: true
    channels: []
    retryCount: null
    retryDelay: 2000
    secure: false

  constructor: (server, nick, @opt) ->
    _.defaults(@opt, self.createDefaults())
    @conn = null

module.exports.Client = Client



