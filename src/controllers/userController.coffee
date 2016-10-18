VError = require 'verror'
moment = require 'moment'
logger = require('../utils/logger.js').create 'userController'
utils = require '../utils/utils.js'
User = require '../models/user.js'
userSrv = require '../services/userService.js'
bottleSrv = require '../services/bottleService.js'

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
    bottle = req.params.bottle
    try
      bottleSrv.validate bottle
    catch error
      res.send 400, error.message
      return next()

    # TODO: bottle normalization

    logger.debug "add to cave: #{bottle.appellation}, #{bottle.producer}, #{bottle.name}, #{bottle.year} / count: #{req.params.count}"

    in_cave = null
    User.findById id
    .then (user) ->
      if !user?
        throw utils.error null, "User #{id} not found", 404

      # checks wether bottle is already in this cave
      in_cave = user.bottles.find (x) ->
        x.bottle.appellation == bottle.appellation && x.bottle.producer == bottle.producer && x.bottle.name == bottle.name && x.bottle.year == bottle.year

      # if so, update counter
      if in_cave?
        logger.debug "found bottle, update"
        in_cave.count += req.params.count
        in_cave.updateDate = moment.utc()
      else
        # otherwise create new entry in array
        logger.debug 'bottle not in cave, create'
        user.bottles.push {
          bottle: bottle
          count: req.params.count
          createDate: moment.utc()
          updateDate: moment.utc()
        }

      user.save()
    .then (user) ->
      if in_cave
        bottle = in_cave
      else
        bottle = user.bottles[user.bottles.length - 1]
      res.send 200, bottle
      # TODO: add to bottle collection, appellation, producer, cepages collections

      return next()
    .catch (err) ->
      logger.error new VError err, 'error adding bottle to cave `%s`', id
      res.send 500, "Error adding bottle"
      return next()

module.exports = exports = UserController
