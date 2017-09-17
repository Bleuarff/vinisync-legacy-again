'use strict'

const redisSessions = require('redis-sessions'),
      uuidv4 = require('uuid/v4'),
      config = require('./config.js'),
      cookies = require('./cookies.js'),
      utils = require('./utils.js'),
      logger = require('swn-logger').create('session'),
      VError = require('verror'),
      util = require('util')

// Manages sessions.
// Calls next() only when session is retrieved and added to req object,
// so no need for async control when handling request
class Session {

  constructor(){
    this.token = null
    this.data = {}
  }

// creates or retrieves session based on session id cookie
  static async handle(req, res, next){
    var session = new Session(),
        sessId = cookies.parse(req.headers.cookie).sessid

    try{
      if (sessId){
        session.token = sessId
        await session.getSession(res, req.clientIp)
      }
      else{
        await session.createSession(res, req.clientIp)
      }
    }
    catch(err){
      logger.error(new VError(err, 'Session error'))
      res.send(500, {error: 'session error'})
      return next(false)
    }

    req.session = session
    return next()
  }

  // Updates the session: saves the current data object
  // Can add 1 key/value to the session and save it, or update multiple keys at once.
  // If no parameter provided, saves the current state
  // @name: session key as string, or key/value object
  // @value: new value for key.
  async update(name, value){
    if (typeof name === 'string')
      this.data[name] = value
    else if (typeof name === 'object' && name !== null){
      // copy name object in session.data (overwrites duplicates)
      this.data = [...this.data, ...name]
    }
    try{
      await redisWrapper.set({
        app: Session.appName,
        token: this.token,
        d: this.data
      })
    }
    catch(err){
      logger.error(new VError(err, 'Error updating'))
    }
  }

  // kills session
  async destroy(){
    try {
      await redisWrapper.kill({
        app: Session.appName,
        token: this.token
      })
    }
    catch(err){
      logger.error(new VError(err, 'Error killing session'))
    }
  }

// Retrieves existing session. Creates a new one if expired.
  async getSession(res, clientIp){
    try{
      let resp = await redisWrapper.get({
        app: Session.appName,
        token: this.token
      })

      // session retrieved
      if (resp.id){
        // logger.debug('session found')
        this.data = resp.d
        return Promise.resolve(this)
      }

      await this.createSession(res, clientIp)
      return Promise.resolve(this)

    }
    catch(err){
      throw new VError(err, 'Error getting session')
    }
  }

  // Creates a new session and a CSRF token
  // @res: response object
  // @clientIp: IP address of the client
  async createSession(res, clientIp){
    try {
      var csrfToken = await utils.generateUniqueToken()
    }
    catch(err){
      throw new VError(err, 'error generating token for new session')
    }

    this.data = {
      start: new Date().toISOString(),
      csrfToken: csrfToken
    }

    try{
      var resp = await redisWrapper.create({
        app: Session.appName,
        ip: clientIp,
        id: uuidv4(),
        ttl: Session.ttl,
        d: this.data
      })
    }
    catch(err){
      throw new VError(err, 'error creating session store')
    }

    // TODO: set as secure when done testing api
    cookies.set(res, 'sessid', resp.token, null, true, false)
    this.token = resp.token
    return Promise.resolve()
  }
}

// Set static properties
Session.appName = config.session.appName
Session.ttl = config.session.duration

// set backend store
const [host, port] = config.session.host.split(':')
Session.store = new redisSessions({
  host: host,
  port: port
})

// Wrapper to promisify calls to backend store
const redisWrapper = {
  create: util.promisify(Session.store.create),
  get: util.promisify(Session.store.get),
  set: util.promisify(Session.store.set),
  kill: util.promisify(Session.store.kill)
}


module.exports = exports = Session
