'use strict'

const restify = require('restify'),
      // config = require('.//utils/config.js'),
      logger = require('swn-logger').create('routes'),
      session = require('../utils/session.js'),
      requestIp = require('request-ip')

const auth = require('./controllers/authController.js'),
      entry = require('./controllers/entryController.js')

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

  //  Init client IP (X-Client-IP/X-Forwarded-For/X-Real-IP...)
  server.use((req, res, next) => {
    req.clientIp = requestIp.getClientIp(req)
    return next()
  })

  server.get('/api/ping', (req, res, next) => {
    res.send(200)
    return next()
  })

  server.use(session.handle)

  server.use(restify.plugins.queryParser({mapParams: true}))
  server.use(restify.plugins.bodyParser({mapParams: true}))

  /* routes defined below*/

  server.put('/api/user/signup', auth.signup)
  server.get('/api/user/signout', auth.signout)

  server.get('/api/entry/:id', entry.get)
}
