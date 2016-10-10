VError = require 'verror'
logger = require('../utils/logger.js').create 'userController'
utils = require '../utils/utils.js'
User = require '../models/user.js'

class UserController

  @get = (req, res, next) ->
    uid = req.params.id
    if uid != req.session.data.uid
      res.send 403

    User.findById uid
    .then (user) ->
      if !user?
        res.send 404, "user #{uid} not found"
        return next()

      res.send 200, user
      next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving user `%s`', uid
      res.send 500, 'Error retrieving user'
      next()

  # @create = (req, res, next) ->
  #   if !utils.hasParams req, res, 'user', false

module.exports = exports = UserController
