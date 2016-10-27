VError = require 'verror'
moment = require 'moment'
ObjectId = require('mongoose').Types.ObjectId
logger = require('../utils/logger.js').create 'userController'
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


  # adds a wine to the cave
  @addWine = (req, res, next) ->
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
        throw utils.error null, "User #{id} not found", 404

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
        throw utils.error null, 'cave/entry not found', 404

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


module.exports = exports = UserController
