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





module.exports = exports = UserService
