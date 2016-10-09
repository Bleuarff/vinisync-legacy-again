cluster = require 'cluster'
restify = require 'restify'

logger = require('./utils/logger.js').create 'server'
config = require './utils/config.js'
routes = require './routes.js'
db = require './utils/db.js'

port = config.server.port # internal port listening
numCPUs = require('os').cpus().length

if config.server.cluster && cluster.isMaster
  # fork
  for i in [0...numCPUs]
    cluster.fork()

  cluster.on 'exit', (worker, code, signal) ->
    #logger.error 'worker #{worker.process.pid} died (#{signal || code})'
    cluster.fork()

  cluster.on 'listening', (worker, address) ->
    console.log 'ok listening'
    #logger.debug 'worker #{worker.process.pid} is listening to #{address.address}:#{address.port}'

else
  server = restify.createServer
    name: 'Vinisync'

  db.init().then () ->
    routes.register server
    server.listen port, '127.0.0.1'
  .catch (err) ->
    console.log err
    logger.error err
    setTimeout () ->
      process.exit 1
    , 10000


process.on 'SIGINT', () -> clean('SIGINT')
process.on 'SIGTERM', () -> clean('SIGTERM')

clean = (signal) ->
  logger.debug "#{signal}: clean & exit"
  db.close().then () ->
    logger.debug 'DB closed'
    process.exit 0
