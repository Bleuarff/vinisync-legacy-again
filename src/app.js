'use strict'

var restify = require('restify'),
    VError = require('verror'),
    cluster = require('cluster'),
    config = require('../utils/config.js'),
    logger = require('swn-logger').create('vinisync', config.log),
    server = require('./server.js')

var port = config.server.port

function runMaster(){
  let numCpus = require('os').cpus().length
  for (let i = 0; i < numCpus; i++){
    cluster.fork()
  }

  cluster.on('exit', (worker, code, signal) => {
    cluster.fork()
  })
  cluster.on('listening', (worker, address) => {
    console.log('ok listening')
  })
}

/**************************

 App entry point

 ***************************/

async function main(){
  if (config.server.cluster && cluster.isMaster) {
    runMaster()
  }
  else {
    try{
      await server.start(config.dbConnections, port)
    }
    catch(err){
      logger.error(err)
      setTimeout(() => {
        process.exit(1)
      }, 10000)
    }
  }
}

main()

// listen to signals, close server
// kill -2 works but keyboard interrupt does not. wtf.
process.on('SIGINT', () => {logger.debug('sigint'); server.stop('SIGINT')})
process.on('SIGTERM', () => {logger.debug('sigterm'); server.stop('SIGTERM')})
process.on('exit', (code) => {
  logger.debug(`exit: ${code}`)
  server.stop('exit')
})
process.on('beforeExit', (code) => {
  logger.debug('beforeExit')
})
