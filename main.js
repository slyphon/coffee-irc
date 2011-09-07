require.paths.unshift('./node_modules');
require.paths.unshift('./lib');
require("coffee-script");

module.exports.client = require('coffee-irc/client');


