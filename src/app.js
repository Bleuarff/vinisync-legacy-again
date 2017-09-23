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
process.on('SIGINT', () => {logger.debug('sigint'); Server.stop('SIGINT')})
process.on('SIGTERM', () => {logger.debug('sigterm'); Server.stop('SIGTERM')})
