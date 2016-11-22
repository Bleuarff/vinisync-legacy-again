restify = require 'restify'

config = require './utils/config.js'
logger =  require('./utils/logger.js').create 'routes'
# declare  handlers
session = require './utils/session.js'
csrf = require './utils/csrf.js'
# declare controllers
user = require './controllers/userController.js'
appellation = require './controllers/appellationController.js'
wine = require './controllers/wineController.js'
cepage = require './controllers/cepageController.js'
producer = require './controllers/producerController.js'

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
    res.header 'content-type', 'application/json'
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
  server.post '/user/signin', user.signin

  server.get '/cave/:id', user.get
  server.put '/cave/:id/entry', user.addEntry
  server.post '/cave/:id/entry/:entryId/increment', user.increment
  server.post '/cave/:id/entry/:entryId/decrement', user.decrement
  server.post '/cave/:id/entry/:entryId', user.updateEntry

  server.put '/wine', wine.create
  server.get '/wine', wine.find
  server.get '/wine/:id', wine.get

  server.get '/cepage', cepage.index
  server.get '/appellation', appellation.index
  server.get '/producer', producer.index

module.exports.register = exports.register = registerRoutes
