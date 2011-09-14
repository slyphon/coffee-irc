assert = require('assert')
{EventEmitter} = require('events')
_ = require('underscore')

{replyFor, message} = require('./../../')

SERVER = 'irc.example.com'
NICK = 'nick-dang'
USER_NAME = 'coffee-irc'
REAL_NAME = 'coffee-irc client'
CRLF = "\r\n"

customMatchers =
  toBeArray: () -> _(@actual).isArray()
  toBeEmpty: () -> _(@actual).isEmpty()
  toDeeplyEqual: (expected) -> _(@actual).isEqual(expected)


describe 'message', ->
  beforeEach ->
    @addMatchers(customMatchers)

  describe 'NOTICE', ->
    notice = ":NickServ!NickServ@services. NOTICE #{NICK} :This nickname is registered."
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
      expect(msg.args).toDeeplyEqual(['nick-dang', 'This nickname is registered.'])

  describe 'topic reply', ->
    topicReply = ":#{SERVER} 332 #{NICK} #Node.js : node.js topic"
    msg = message.parse(topicReply)

    it 'should parse out the command and replace the numeric with symbolic name', ->
      expect(msg.command).toEqual('rpl_topic')

    it 'should have the rawCommand', ->
      expect(msg.rawCommand).toEqual('332')

    it 'should have a null nick', ->
      expect(msg.nick).toBeNull()

    it 'should have a null user', ->
      expect(msg.user).toBeNull()

    it 'should set the commandType', ->
      expect(msg.commandType).toEqual('reply')

    it 'should parse out the server', ->
      expect(msg.server).toEqual(SERVER)
    
    it 'should parse out the arguments', ->
      expect(msg.args).toDeeplyEqual([NICK, '#Node.js', ' node.js topic'])

  describe 'PRIVMSG', ->
    client =
      nick: NICK

    describe 'to channel, not to us', ->
      privmsgToChan = ':dingus!moot@1.2.3.4 PRIVMSG #python :If you catch them'
      msg = message.parse(privmsgToChan, client)

      it 'should parse the message', ->
        expect( msg.command      ).toEqual('PRIVMSG')
        expect( msg.rawCommand   ).toEqual('PRIVMSG')
        expect( msg.commandType  ).toEqual('normal')
        expect( msg.nick         ).toEqual('dingus')
        expect( msg.user         ).toEqual('moot')
        expect( msg.host         ).toEqual('1.2.3.4')
        expect( msg.server       ).toBeNull()

      it 'should include the PrivmsgMixin functions', ->
        expect(msg.isPrivmsg()).toBeTruthy()
      
      it 'should not be to us', ->
        expect(msg.isToUs()).not.toBeTruthy()

      it 'should have a channel', ->
        expect(msg.channel).toEqual('#python')

      it 'should be public', ->
        expect(msg.isPublic()).toBeTruthy()

      it 'should have the correct text', ->
        expect(msg.text).toEqual('If you catch them')

    describe 'to channel, directed to us', ->
      privmsgToChan = ":dingus!moot@1.2.3.4 PRIVMSG #python :#{NICK}: If you catch them"
      msg = message.parse(privmsgToChan, client)

      it 'should parse the message', ->
        expect( msg.command      ).toEqual('PRIVMSG')
        expect( msg.rawCommand   ).toEqual('PRIVMSG')
        expect( msg.commandType  ).toEqual('normal')
        expect( msg.nick         ).toEqual('dingus')
        expect( msg.user         ).toEqual('moot')
        expect( msg.host         ).toEqual('1.2.3.4')
        expect( msg.server       ).toBeNull()

      it 'should include the PrivmsgMixin functions', ->
        expect(msg.isPrivmsg()).toBeTruthy()
      
      it 'should be to us', ->
        expect(msg.isToUs()).toBeTruthy()

      it 'should have a channel', ->
        expect(msg.channel).toEqual('#python')

      it 'should be public', ->
        expect(msg.isPublic()).toBeTruthy()

      it 'should have the correct text', ->
        expect(msg.text).toEqual("#{NICK}: If you catch them")

    describe 'directly to us', ->
      privmsgToUs = ":slyphon!~weechat@unaffiliated/slyphon PRIVMSG #{NICK} :is you is or is you ain't mah baby"
      msg = message.parse(privmsgToUs, client)

      it 'should parse the message', ->
        expect( msg.command      ).toEqual('PRIVMSG')
        expect( msg.rawCommand   ).toEqual('PRIVMSG')
        expect( msg.commandType  ).toEqual('normal')
        expect( msg.nick         ).toEqual('slyphon')
        expect( msg.user         ).toEqual('~weechat')
        expect( msg.host         ).toEqual('unaffiliated/slyphon')
        expect( msg.server       ).toBeNull()

      it 'should include the PrivmsgMixin functions', ->
        expect(msg.isPrivmsg()).toBeTruthy()
      
      it 'should be to us', ->
        expect(msg.isToUs()).toBeTruthy()

      it 'should not have a channel', ->
        expect(msg.channel).not.toBeTruthy()

      it 'should not be public', ->
        expect(msg.isPublic()).not.toBeTruthy()

      it 'should have the correct text', ->
        expect(msg.text).toEqual("is you is or is you ain't mah baby")



