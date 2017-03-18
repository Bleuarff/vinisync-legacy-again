moment = require 'moment'
VError = require 'verror'
bcrypt = require 'bcrypt'
logger = require('../utils/logger.js').create 'userService'
User = require '../models/user.js'
utils = require '../utils/utils.js'

class UserService

  @load: (uid) ->
    if !uid? || uid == ''
      err = new VError "missing parameter uid"
      err.status = 400
      throw error

    User.findById uid
    .then (user) ->
      if !user?
        throw utils.error "user #{uid} not found", 404

      logger.debug "user: #{user.name}"
      return Promise.resolve user

  @validate: (profile) ->
    errs = {}
    if utils.isNullOrEmpty profile.email
      errs.noEmail = true
    else if !/.+@.+\..+/i.test(profile.email)
      errs.invalidEmail = true
    if utils.isNullOrEmpty(profile.name)
      errs.noName = true
    if utils.isNullOrEmpty(profile.pwd)
      errs.noPwd1  = true
    else if (profile.pwd.length < 8)
      errs.shortPwd = true

    return errs


  @create: (profile) ->
    logger.info 'create user'
    bcrypt.hash profile.pwd, 12
    .then (hash) ->
      # ready to create a new user
      profile.pwd = hash
      profile.enabled = true
      profile.confirmed = false
      profile.createDate = moment.utc()
      user = new User profile
      return user.save()


module.exports = exports = UserService
