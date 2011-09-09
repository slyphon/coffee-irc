assert = require('assert')
{EventEmitter} = require('events')
_ = require('underscore')

{Client, replyFor} = require('./../../')

SERVER = 'irc.example.com'
NICK = 'nick-danger'
USER_NAME = 'coffee-irc'
REAL_NAME = 'coffee-irc client'

customMatchers =
  toBeArray: () -> _(@actual).isArray()
  toBeEmpty: () -> _(@actual).isEmpty()

describe 'Client', ->
  client = null

  beforeEach ->
    @addMatchers(customMatchers)
    opts =
      realName: REAL_NAME
      userName: USER_NAME
      
    client = new Client SERVER, NICK, opts

  describe "construction with default opts", ->
    it 'should have an empty channels property', ->
      channels = client.opt.channels
      expect(channels).toBeArray()
      expect(channels).toBeEmpty()

  describe 'connection', ->
    socket = null

    resetSocket = ->
      socket = new EventEmitter()
      _(socket).extend
        setTimeout: -> {}
        setEncoding: -> {}

    beforeEach ->
      resetSocket()
      spyOn(Client.net, 'createConnection').andReturn(socket)

    describe 'insecure', ->
      it 'should create the connection with the appropriate server and port', ->
        client.connect()
        expect(Client.net.createConnection).toHaveBeenCalledWith(SERVER, 6667)
      
      it 'should setEncoding to UTF8', ->
        spyOn(socket, 'setEncoding')
        client.connect()
        expect(socket.setEncoding).toHaveBeenCalledWith('utf8')

      it 'should listen for the connect event on the socket', ->
        spyOn(socket, 'write')
#         connected_cb = jasmine.createSpy()
#         client.connect(connected_cb)
#         socket.emit('connect')
#         expect(socket.write).toHaveBeenCalledWith("NICK :#{NICK}")
#         expect(socket.write).toHaveBeenCalledWith("USER #{USER_NAME} 8 * :#{REAL_NAME}")


