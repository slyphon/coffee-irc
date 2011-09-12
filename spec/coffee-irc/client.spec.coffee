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
        write: -> {}

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

      describe 'on connection', ->
        beforeEach ->
          spyOn(socket, 'write')
          connected_cb = jasmine.createSpy()
          client.connect(connected_cb)
          socket.emit('connect')

        it 'should register the nickname', ->
          expect(socket.write.argsForCall[0][0]).toEqual("NICK #{NICK.substr(0,9)}\r\n")

        xit 'should send the USER command', ->
          expect(socket.write).toHaveBeenCalledWith("USER #{USER_NAME} 8 * :#{REAL_NAME}")


