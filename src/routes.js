'use strict'

const restify = require('restify'),
      // config = require('.//utils/config.js'),
      logger = require('swn-logger').create('routes')

module.exports.register = exports.register = function registerRoutes(server){
  /* First register handlers */

  server.pre(restify.pre.sanitizePath()) // normalize urls

  server.use((req, res, next) => {
    res.charSet('utf-8') // set utf-8 for all requests
    // set no cache for all requests
    res.header('Cache-Control', 'private, no-cache, no-store, must-revalidate')
    res.header('content-type', 'application/json')
    next()
  })

  // log incoming requests
  server.use((req, res, next) => {
    logger.debug(`${req.method} ${req.getPath()}`)
    return next()
  })

  server.use(restify.plugins.queryParser({mapParams: true}))
  server.use(restify.plugins.bodyParser({mapParams: true}))

  /* routes defined below*/

}
