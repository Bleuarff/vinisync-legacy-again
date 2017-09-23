'use strict'

const VError = require('verror'),
      restify = require('restify'),
      logger = require('swn-logger').create('server'),
      db = require('node-db-connector'),
      routes = require('./routes.js')

var server // restify server

class Server{

    static async start(dbConnections, port){
      try{
        server = restify.createServer({
          name: 'Vinsync',
          version: '1.0.0' // defaut version for routes
        })

        await db.init(dbConnections, {logger: logger})
        routes.register(server)
        server.listen(port, '127.0.0.1')
        logger.info('listening...')
        return server
      }
      catch(err){
        throw new VError(err, 'Error creating server')
      }


    }

    // close restify server
    static async stop(signal){
      logger.debug(signal + ': clean & exit')
      await db.close()
      server.close()
      logger.debug('DBs closed')
      process.exit(0)
    }
}

module.exports = exports = Server
