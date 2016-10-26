VError = require 'verror'
moment = require 'moment'
ObjectId = require('mongoose').Types.ObjectId
logger = require('../utils/logger.js').create 'userController'
utils = require '../utils/utils.js'
User = require '../models/user.js'
userSrv = require '../services/userService.js'
bottleSrv = require '../services/bottleService.js'
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


  # adds a bottle to the cave
  @addBottle = (req, res, next) ->
    id = req.params.id
    try
      bottleSrv.validate req.params.bottle
    catch error
      logger.info new VError error, "invalid bottle parameters"
      res.send 400, error.message
      return next()

    bottle = normalizer.normalize req.params.bottle
    logger.debug "add to cave: #{bottle.appellation}, #{bottle.producer}, #{bottle.name}, #{bottle.year} / count: #{req.params.count}"
    in_cave = null

    User.findById id
    .then (user) ->
      if !user?
        throw utils.error null, "User #{id} not found", 404

      # checks wether bottle is already in this cave
      in_cave = user.bottles.find (x) ->
        x.bottle.appellation == bottle.appellation && x.bottle.producer == bottle.producer &&
        x.bottle.name == bottle.name && x.bottle.year == bottle.year

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
          bottle: bottle
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

      # add to bottle collection (and subsequently to appellation, producer, cepages collections)
      bottleSrv.propagate entry.bottle
      .then () ->
        return next()
      .catch (err) ->
        # on error, log but do not send error to client - bottle has been added to the cave OK
        logger.error new VError err, 'Error creating bottle'
        return next()
    .catch (err) ->
      logger.error new VError err, 'error adding bottle to cave `%s`', id
      res.send 500, "Error adding bottle"
      return next()


  # increments an entry count by 1
  @increment = (req, res, next) ->
    try
      caveId = new ObjectId req.params.id
      entryId = new ObjectId req.params.entryId
    catch ex
      res.send 400, 'invalid parameters'
      return next()

    userSrv.updateEntryCount caveId, entryId, 1
    .then (ok) ->
      if ok
        res.send 204
      else
        res.send 404, 'cave/entry not found'
      return next()
    .catch (err) ->
      logger.error new VError 'Error incrementing entry %s for user %s', entryId, caveId
      res.send 500, 'error incrementing bottle count'
      return next()


  # decrements an entry count by 1, or remove entry
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

      # remove entry if no more bottle
      if entry.count <= 0
        cave.bottles.splice idx, 1

      cave.save()
    .then () ->
      res.send 200, {count: newCount}
      return next()
    .catch (err) ->
      logger.error new VError err,'Error decrementing entry  %s for user %s', entryId, caveId
      res.send err.status || 500, 'error decrementing bottle count'
      return next()


module.exports = exports = UserController
