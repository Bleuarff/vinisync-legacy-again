moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'userService'
User = require '../models/user.js'

class UserService

  @load: (uid) ->
    if !uid? || uid == ''
      err = new VError "missing parameter uid"
      err.status = 400
      throw error

    User.findById uid
    .then (user) ->
      if !user?
        err = new VError "user #{uid} not found"
        err.status = 404
        throw err

      logger.debug "user: #{user.name}"
      return Promise.resolve user

  @create: (profile) ->
    logger.info 'create user'
    profile.email = profile.email.toLowerCase()
    # Check email is not already registered for that application
    User.findOne { email: profile.email }
    .then (result) ->
      if result?
        throw new VError 'email %s already exists', profile.email

      # ready to create a new user
      profile.enabled = true
      profile.createDate = moment.utc()
      user = new User profile
      return user.save()


module.exports = exports = UserService
