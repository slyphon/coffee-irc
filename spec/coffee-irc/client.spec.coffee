assert = require('assert')

_ = require('underscore')

{Client, replyFor} = require('./../../')

SERVER = 'irc.example.com'
NICK = 'nick-danger'

customMatchers =
  toBeArray: () -> _(@actual).isArray()
  toBeEmpty: () -> _(@actual).isEmpty()

describe 'Client', ->
  client = null

  beforeEach ->
    @addMatchers(customMatchers)
    client = new Client SERVER, NICK

  describe "construction with default opts", ->
    it 'should have an empty channels property', ->
      channels = client.opt.channels
      expect(channels).toBeArray()
      expect(channels).toBeEmpty()

  describe "insecure", ->
    bogusSocket =
      setTimeout: -> {}
      setEncoding: -> {}
      addListener: -> {}

    beforeEach ->
      spyOn(Client.net, 'createConnection').andReturn(bogusSocket)

    describe 'connect', ->
      it 'should create the connection with the appropriate server and port', ->
        client.connect()
        expect(Client.net.createConnection).toHaveBeenCalledWith(SERVER, 6667)


