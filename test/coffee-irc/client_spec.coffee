{Client, replyFor} = require('./../../')

vows = require('vows')
assert = require('assert')

SERVER = 'irc.example.com'
NICK = 'nick-danger'

vows.describe('client_vows').addBatch({
  "construction with default opts":
    topic: () ->
      new Client SERVER, NICK

    'it should have an empty channels property': (client) ->
      channels = client.opt.channels
      assert.isArray(channels)
      assert.isEmpty(channels)


}).run()


