sys = require('sys')
_ = require('underscore')

{EventEmitter2} = require('eventemitter2')

class MessageEmitter extends EventEmitter2
  # a message instance 
  received: (message) ->


