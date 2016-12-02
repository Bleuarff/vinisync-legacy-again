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
      logger.debug "user: #{JSON.stringify user}"
      logger.debug "instanceof user: " + user instanceof Promise
      res.send 200, user
      next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving user `%s`', uid
      res.send err.status || 500, 'Error retrieving user'
      next()


  @bottles = (req, res, next) ->
    uid = req.params.id
    offset = parseInt(req.params.offset, 10) || 0
    pageCount = parseInt(req.params.count, 10) || 20
    totalCount = 0
    userSrv.load uid
    .then (user) ->
      bottleCount = user.bottles.reduce (prev, cur) ->
        return prev + cur.count
      , 0

      data =
        entryCount: user.bottles.length
        bottles: user.bottles.slice offset, offset + pageCount
        bottleCount: bottleCount

      res.send 200, data
      next()
    .catch (err) ->
      logger.error new VError 'Error retrieving bottles for user %s', uid
      res.send err.status || 500, 'Error retrieving bottles'
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


  # adds a wine to the cave
  @addEntry = (req, res, next) ->
    id = req.params.id
    try
      wineSrv.validate req.params.wine
    catch error
      logger.info new VError error, "invalid wine parameters"
      res.send 400, error.message
      return next()

    wine = normalizer.normalize req.params.wine
    logger.debug "add to cave: #{wine.appellation}, #{wine.producer}, #{wine.name}, #{wine.year} / count: #{req.params.count}"
    in_cave = null

    User.findById id
    .then (user) ->
      if !user?
        throw utils.error "User #{id} not found", 404

      # checks wether wine is already in this cave
      in_cave = user.bottles.find (x) ->
        x.wine.appellation == wine.appellation && x.wine.producer == wine.producer &&
        x.wine.name == wine.name && x.wine.year == wine.year

      # if so, update counter
      if in_cave?
        # TODO: if cepages provided and != from existing entry, update
        logger.debug "found entry, update"
        in_cave.count += req.params.count
        in_cave.updateDate = moment.utc()
      else
        # otherwise create new entry in array
        logger.debug 'entry not found, create'
        user.bottles.push {
          wine: wine
          count: req.params.count
          offeredBy: req.params.offeredBy
          createDate: moment.utc()
          updateDate: moment.utc()
        }

      user.save()
    .then (user) ->
      if in_cave
        entry = in_cave
      else
        entry = user.bottles[user.bottles.length - 1]
      res.send 200, entry

      # add to winee collection (and subsequently to appellation, producer, cepages collections)
      wineSrv.propagate entry.wine
      .then () ->
        return next()
      .catch (err) ->
        # on error, log but do not send error to client - wine has been added to the cave OK
        logger.error new VError err, 'Error creating wine'
        return next()
    .catch (err) ->
      logger.error new VError err, 'error adding wine to cave `%s`', id
      res.send 500, "Error adding wine"
      return next()


  # increments an entry count by 1
  @increment = (req, res, next) ->
    try
      caveId = new ObjectId req.params.id
      entryId = new ObjectId req.params.entryId
    catch ex
      res.send 400, 'invalid parameters'
      return next()

    User.findOneAndUpdate {_id: caveId, 'bottles._id': entryId}, {
      $inc: {'bottles.$.count': 1}
      $set: {'bottles.$.updateDate': moment.utc()}
    }, {new: true}
    .then (cave) ->
      if !cave?
        res.send 404, 'cave/entry not found'
      else
        entry = cave.bottles.find (x) -> x._id.equals entryId
        res.send 200, {count: entry.count}
      return next()
    .catch (err) ->
      logger.error new VError 'Error incrementing entry %s for user %s', entryId, caveId
      res.send 500, 'error incrementing entry count'
      return next()


  # decrements an entry count by 1, or removes entry
  @decrement = (req, res, next) ->
    try
      caveId = new ObjectId req.params.id
      entryId = new ObjectId req.params.entryId
    catch ex
      res.send 400, 'invalid parameters'
      return next()

    newCount = -1

    User.findOne {_id: caveId, 'bottles._id': entryId}
    .then (cave) ->
      if !cave?
        throw utils.error 'cave/entry not found', 404

      idx = cave.bottles.findIndex (x) -> x._id.equals entryId
      entry = cave.bottles[idx]
      newCount = entry.count -= 1
      entry.updateDate = moment.utc()

      # remove entry if no more bottles
      if entry.count <= 0
        cave.bottles.splice idx, 1

      cave.save()
    .then () ->
      res.send 200, {count: newCount}
      return next()
    .catch (err) ->
      logger.error new VError err,'Error decrementing entry  %s for user %s', entryId, caveId
      res.send err.status || 500, 'error decrementing entry count'
      return next()


  # updates an entry with the given params
  @updateEntry = (req, res, next) ->
    try
      caveId = new ObjectId req.params.id
      entryId = new ObjectId req.params.entryId
    catch ex
      res.send 400, 'invalid parameters'
      return next()

    # return error if no parameter provided
    if !req.params.appellation? && !req.params.producer? &&!req.params.name? && !req.params.year? && !req.params.cepages?
      res.send 400, 'no parameter to update'
      return next()

    entry = null

    User.findById caveId
    .then (cave) ->
      if !cave?
        throw utils.error 'cave not found', 404

      # looks for entry
      entry = cave.bottles.find (x) -> x._id.equals entryId
      if !entry?
        throw utils.error 'entry not found', 404

      # build object with update values, or existing values for mandatory fields if not provided
      update = {
        appellation: req.params.appellation || entry.wine.appellation
        producer: req.params.producer || entry.wine.producer
        name: req.params.name
        year: req.params.year
        cepages: req.params.cepages || []
      }

      wineSrv.validate update
      update = normalizer.normalize update

      # applies new values
      entry.wine.appellation = update.appellation
      entry.wine.producer = update.producer
      if update.name?
        entry.wine.name = update.name
      if update.year?
        entry.wine.year = update.year
      if update.cepages?
        entry.wine.cepages = update.cepages

      cave.save()
    .then () ->
      res.send 200, entry
      # add to wine collection (and subsequently to appellation, producer, cepages collections)
      wineSrv.propagate entry.wine
      .then () ->
        return next()
      .catch (err) ->
        # on error, log but do not send error to client - wine has been added to the cave OK
        logger.error new VError err, 'Error creating wine'
        return next()
    .catch (err) ->
      logger.error new VError err, 'Error updating entry %s for user %s', req.params.entryId, req.params.id
      switch err.status
        when 400 then msg = 'invalid parameters'
        else msg = 'error updating entry'
      res.send err.status || 500, msg
      return next()

module.exports = exports = UserController
