VError = require 'verror'
logger = require('../utils/logger.js').create 'userController'
utils = require '../utils/utils.js'
User = require '../models/user.js'
userSrv = require '../services/userService.js'

class UserController

  @get = (req, res, next) ->
    uid = req.params.id
    # if uid != req.session.data.uid
    #   res.send 403
    #   return next()

    userSrv.load uid
    .then (user) ->
      logger.debug "user: #{JSON.stringify user}"
      logger.debug "instanceof user: " + user instanceof Promise
      res.send 200, user
      next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving user `%s`', uid
      res.send err.status || 500, 'Error retrieving user'
      next()


  @addBottle: (req, res, next) ->
    uid = req.params.uid
    if uid != req.session.data.uid
      res.send 403
      return next()

    User.findById uid
    .then (user) ->
      if !user?
        res.send 404, "user #{uid} not found"

module.exports = exports = UserController
