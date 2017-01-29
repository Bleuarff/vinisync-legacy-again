VError = require 'verror'
moment = require 'moment'
ObjectId = require('mongoose').Types.ObjectId
restify = require 'restify'
logger = require('../utils/logger.js').create 'userController'
config = require '../utils/config.js'
utils = require '../utils/utils.js'
User = require '../models/user.js'
userSrv = require '../services/userService.js'
wineSrv = require '../services/wineService.js'
normalizer = require '../services/normalizer.js'

class UserController

  @get = (req, res, next) ->
    uid = req.params.id
    # if uid != req.session.data.uid
    #   res.send 403
    #   return next()

    userSrv.load uid
    .then (user) ->
      # logger.debug "user: #{JSON.stringify user}"
      # logger.debug "instanceof user: " + user instanceof Promise
      res.send 200, user
      next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving user `%s`', uid
      res.send err.status || 500, 'Error retrieving user'
      next()


  ###
  # authenticate user, set user data into session
  ###
  @_authenticate = (req, user) ->
    if !user.enabled
      throw new VError 'user {id: %s, email: %s} is disabled', user.id, user.email

    req.session.data.uid = user.id
    req.session.data.firstName = user.firstName
    req.session.update()

    utils.generateUniqueToken(24) # generates unique token
    .then (token) ->
      req.session.update('csrfToken', token) # add new token to session
      return user

  ###
  # signin request
  ###
  @signin = (req, res, next) ->
    if !utils.hasParams req, res, 'token', false
      return next()

    token = req.params.token
    userProfile = null

    p = new Promise (resolve, reject) ->
      client = restify.createJsonClient
        url: 'https://www.googleapis.com'
        version: '~1.0'
        agent: false

      client.get "/oauth2/v3/tokeninfo?id_token=#{token}", (error, req, res, obj) ->
        if error
          reject new VError 'can not retrieve tokeninfo via googleapis'
        else if obj.error_description
          reject new VError obj.error_description
        else if obj.aud != config.auth.googleApiId
          reject new VError 'invalid audience'
        else
          resolve { email: obj.email, firstName: obj.given_name, lastName: obj.family_name}

    p.then (profile) ->
      userProfile = profile
      User.findOne { email: userProfile.email }, {bottles: 0}
    .then (user) ->
      if !user? && userProfile
        return userSrv.create userProfile
      else
        return user
    .then (user) ->
      UserController._authenticate req, user
    .then (user) ->
      res.send 200, {user: user, csrfToken: req.session.data.csrfToken}
      next()
    .catch (err) ->
      logger.error new VError err, 'Signin error'
      res.send 400, 'invalid token'
      next()


module.exports = exports = UserController
