assert = require('assert')
{EventEmitter} = require('events')
_ = require('underscore')

{replyFor, message} = require('./../../')

CRLF = "\r\n"

customMatchers =
  toBeArray: () -> _(@actual).isArray()
  toBeEmpty: () -> _(@actual).isEmpty()
  toBeDeeplyEqual: (expected) -> _(@actual).isEqual(expected)


describe 'message', ->
  beforeEach ->
    @addMatchers(customMatchers)

  xdescribe 'NOTICE', ->
    notice = ":NickServ!NickServ@services. NOTICE nick-dang :This nickname is registered."
    msg = message.parse(notice)

    it 'should parse out the command', ->
      expect(msg.command).toEqual('NOTICE')

    it 'should parse out the nick', ->
      expect(msg.nick).toEqual('NickServ')

    it 'should parse the user', ->
      expect(msg.user).toEqual('NickServ')

    it 'should set the commandType', ->
      expect(msg.commandType).toEqual('normal')

    it 'should parse out the arguments', ->
      expect(msg.args).toBeDeeplyEqual(['nick-dang', 'This nickname is registered.'])

  describe 'topic reply', ->
    topicReply = ':verne.freenode.net 332 nick-dang #Node.js : node.js topic'
    msg = message.parse(topicReply)

    it 'should parse out the command and replace the numeric with symbolic name', ->
      expect(msg.command).toEqual('rpl_topic')
      console.dir(msg)

    it 'should have the rawCommand', ->
      expect(msg.rawCommand).toEqual('332')

    it 'should have a null nick', ->
      expect(msg.nick).toBeNull()

    it 'should have a null user', ->
      expect(msg.user).toBeNull()

    it 'should set the commandType', ->
      expect(msg.commandType).toEqual('reply')

    it 'should parse out the server', ->
      expect(msg.server).toEqual('verne.freenode.net')
    
    it 'should parse out the arguments', ->
      expect(msg.args).toBeDeeplyEqual(['nick-dang', '#Node.js', ' node.js topic'])


