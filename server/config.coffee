americano = require 'americano'
fs = require 'fs'

# public path depends on what app is running (./server or ./build/server)
publicPath = __dirname + '/../client/public'
try
    fs.lstatSync publicPath
catch e
    publicPath = __dirname + '/../../client/public'

config =
    common: [
        (req, resp, next) ->
            sockets = require('http').globalAgent.sockets
            for origin, s of sockets
                console.log origin, s?.length
                for t in s
                    console.log t?._httpMessage?.path
            next()

        americano.bodyParser()
        americano.methodOverride()
        americano.errorHandler
            dumpExceptions: true
            showStack: true
        americano.static publicPath,
            maxAge: 86400000
    ]
    development: [
        americano.logger 'dev'
    ]
    production: [
        americano.logger 'short'
    ]
    plugins: [
        'americano-cozy'
    ]

module.exports = config
