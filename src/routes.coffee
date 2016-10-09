restify = require 'restify'

config = require './utils/config.js'
logger =  require('./utils/logger.js').create 'routes'
# declare  handlers
session = require './utils/session.js'
csrf = require './utils/csrf.js'
# declare controllers
user = require './controllers/userController.js'

registerRoutes = (server) ->
  logger.debug 'registering handlers & routes'
  csrf.cookies = ['rmrid', 'sessid']

  # First register handlers
  server.pre restify.pre.sanitizePath() # normalize urls

  server.use (req, res, next) ->
    res.charSet "utf-8" # set utf-8 for all requests
    # set no cache for all requests
    res.header 'Cache-Control', 'private, no-cache, no-store, must-revalidate'
    res.header 'Expires', '-1'
    res.header 'Pragma', 'no-cache'
    next()

  # log all incoming queries
  server.use (req, res, next) -> logger.debug req.getPath(); next()

  # maintenance mode
  if config.disabled
    server.use (req, res, next) ->
      res.header 'Content-Type', 'text/plain'
      res.send 503, 'down for maintenance'

  server.use restify.queryParser({mapParams: true})
  server.use restify.bodyParser({mapParams: true})
  server.use session.handle # creates or retrieves session and attach it to request object
  # server.use user.checkAuth # remember me feature
  # server.use csrf.checkToken # CSRF verification

  # then register routes
  server.get '/user/:id', user.get

module.exports.register = exports.register = registerRoutes
