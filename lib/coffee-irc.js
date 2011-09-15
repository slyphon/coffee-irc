require.paths.unshift('../node_modules');
require("coffee-script");

var client = require('./coffee-irc/client');

module.exports.Client  = client.Client;
module.exports.Mode    = client.Mode;
module.exports.Channel = client.Channel;

module.exports.replyFor = require('./coffee-irc/replyFor')
module.exports.message = require('./coffee-irc/message')

