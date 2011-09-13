assert = require('assert')
{EventEmitter} = require('events')
_ = require('underscore')

{Client, replyFor} = require('./../../')

SERVER = 'irc.example.com'
NICK = 'nick-danger'
USER_NAME = 'coffee-irc'
REAL_NAME = 'coffee-irc client'
CRLF = "\r\n"

customMatchers =
  toBeArray: () -> _(@actual).isArray()
  toBeEmpty: () -> _(@actual).isEmpty()

  # any one of a spy's argsForCall matches, then we're true
  toHaveBeenCalledAtAnyTimeWith: (args) ->
    _.any @actual.argsForCall, (actualArgs) ->
      _(actualArgs).isEqual(args)


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
    socket = connected_cb = null

    resetSocket = ->
      socket = new EventEmitter()
      _(socket).extend
        setTimeout: -> {}
        setEncoding: -> {}
        write: -> {}

    shouldHaveWrittenToSocket = (line) ->
      expect(socket.write).toHaveBeenCalledAtAnyTimeWith([line + CRLF])


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
          shouldHaveWrittenToSocket("NICK #{NICK.substr(0,9)}")

        it 'should send the USER command', ->
          shouldHaveWrittenToSocket("USER #{USER_NAME} 8 * :#{REAL_NAME}")

        it 'should emit the connect event', ->
          expect(connected_cb).toHaveBeenCalled()



