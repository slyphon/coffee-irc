require.paths.unshift('../node_modules');
require("coffee-script");

module.exports.Client = require('./coffee-irc/client');
module.exports.replyFor = require('./coffee-irc/replyFor')
module.exports.message = require('./coffee-irc/message')

