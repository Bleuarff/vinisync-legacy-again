'use strict'

var restify = require('restify'),
    VError = require('verror'),
    cluster = require('cluster'),
    config = require('../utils/config.js'),
    logger = require('swn-logger').create('vinisync', config.log),
    db = require('node-db-connector', {logger: logger}),
    routes = require('./routes.js')

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
    let server = restify.createServer({
      name: 'Vinsync',
      version: '1.0.0' // defaut version for routes
    })

    try{
      await db.init(config.dbConnections, {logger: logger})
      routes.register(server)
      server.listen(port, '127.0.0.1')
      logger.info('listening...')
    }
    catch(err){
      logger.error(err)
      setTimeout(()=>{
        process.exit(1)
      }, 10000)
    }
  }
}

main()


process.on('SIGINT', () => {clean('SIGINT')})
process.on('SIGTERM', () => {clean('SIGTERM')})

function clean(signal) {
  logger.debug(signal + ': clean & exit')
  db.close().then(() => {
    logger.debug('DBs closed')
    process.exit(0)
  })
}
