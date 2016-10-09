redisSessions = require 'redis-sessions'
uuid = require 'uuid'
config = require './config.js'
cookies = require './cookies.js'
utils = require './utils.js'

logger = require('./logger.js').create 'session'
VError = require 'verror'

# Manages sessions.
# Calls next() only when session is retrieved and added to req object,
# so no need for async control when handling request
class Session

  @appName = config.session.appName
  @ttl = config.session.duration

  # static backend store
  @store = new redisSessions
    host: config.session.host
    port: config.session.port

  constructor: (@token, @data) ->

  # creates or retrieves session based on session id cookie
  @handle = (req, res, next) ->
    session = new Session()
    sessid = cookies.parse(req.headers.cookie).sessid
    if sessid
      # logger.debug 'Got session id: ' + sessid
      session.token = sessid
      fn = session._getSession
    else
      logger.debug 'Create session'
      fn = session._createSession

    promise = fn.call session, res, req.connection.remoteAddress
    promise.then () ->
      req.session = session
      next()
    promise.catch (err) ->
      logger.error new VError err, 'session error'
      res.send 500, { msg: 'session error' }
      next(false)

  # Updates the session: saves the current data object
  # Can add 1 key/value to the session and save it, or update multiple keys at once.
  # If no parameter provided, saves the current state
  # @name: session key as string, or key/value object
  # @value: new value for key.
  update: (name = null, value = null) ->
    if typeof name == 'string'
      @data[name] = value
    else if name? && typeof name == 'object'
      params = name
      for key in Object.keys params
        @data[key] = params[key]

    Session.store.set
      app: Session.appName
      token: @token
      d: @data
    , (err, resp) ->
      if err
        logger.error 'ERROR', err

  # Kills the current session
  destroy: () ->
    Session.store.kill
      app: Session.appName
      token: @token
    , (err, resp) ->
      if err
        logger.error 'ERROR', err

  # Retrieves existing session. Creates a new one if expired.
  # @res: response object
  # @clientIp: IP address of the client
  _getSession: (res, clientIp) ->
    promise = new Promise (resolve, reject) =>
      Session.store.get
        app: Session.appName
        token: @token
      , (err, resp) =>
        if err
          reject err
        else if resp.id?
          @data = resp.d
          resolve this
        else # session expired
          @_createSession res, clientIp
          .then () =>
            resolve this
          .catch (err) ->
            reject err

    return promise

  # Creates a new session and a CSRF token
  # @res: response object
  # @clientIp: IP address of the client
  _createSession: (res, clientIp) ->
    promise = new Promise (resolve, reject) =>
      utils.generateUniqueToken(24)
      .then (csrfToken) =>
        @data = {
          start: (new Date()).toISOString()
          csrfToken: csrfToken
        }

        # init new session
        Session.store.create
          app: Session.appName
          ip: clientIp
          id: uuid.v4() # generate new unique id
          ttl: Session.ttl
          d: @data
        , (err, resp) =>
          if err
            reject err
          else
            cookies.set res, 'sessid', resp.token # set session cookie
            @token = resp.token
            resolve this
      .catch (err) ->
        reject err

    return promise

  # Retrieves promotion Ids subscribed by non-authenticated user
  getPromos: () ->
    return if utils.isNullOrEmpty(@data.promoIds) then [] else @data.promoIds.split ','

  # Persists subscribed promotion in session.
  # /!\ Does not perform partial update, rewrites completely the subscribed promotions
  # @subscribed: promotions id array
  setPromos: (subscribed) ->
    if utils.isNullOrEmpty subscribed
      subscribed = []
    else if typeof subscribed == 'string'
      subscribed = [subscribed]

    @update 'promoIds', subscribed.join(',')

module.exports = exports = Session
