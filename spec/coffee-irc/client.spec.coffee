assert = require('assert')
_ = require('underscore')

{Client, replyFor} = require('./../../')

SERVER = 'irc.example.com'
NICK = 'nick-danger'

customMatchers =
  toBeArray: () -> _(@actual).isArray()
  toBeEmpty: () -> _(@actual).isEmpty()

describe 'Client', ->
  beforeEach ->
    @addMatchers(customMatchers)

  describe "construction with default opts", ->
    client = null

    beforeEach ->
      client = new Client SERVER, NICK

    it 'should have an empty channels property', ->
      channels = client.opt.channels
      expect(channels).toBeArray()
      expect(channels).toBeEmpty()


