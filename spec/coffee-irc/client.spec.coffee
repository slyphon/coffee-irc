vows = require('vows')
assert = require('assert')
gently = require('gently')

{Client, replyFor} = require('./../../')

SERVER = 'irc.example.com'
NICK = 'nick-danger'

client = new Client, SERVER, NICK

vows.describe('client_vows').addBatch({
  "construction with default opts":
    topic: () ->
      new Client SERVER, NICK

    'it should have an empty channels property': (client) ->
      channels = client.opt.channels
      assert.isArray(channels)
      assert.isEmpty(channels)

  "connect":
    topic: () ->

      

}).run()


