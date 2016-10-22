moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'bottleController'
utils = require '../utils/utils.js'
Bottle = require '../models/bottle.js'
bottleSrv = require '../services/bottleService.js'
normalizer = require '../services/normalizer.js'

class BottleController

  # Warning: creates duplicates, no first check
  @create = (req, res, next) ->
    try
      bottleSrv.validate req.params.bottle
    catch ex
      res.send 400, ex.message
      return next()

    bottle = normalizer.normalize req.params.bottle
    bottleSrv.create bottle
    .then (b) ->
      res.send 201, b
      next()
    .catch (err) ->
      logger.error new VError 'Error creating bottle'
      res.send err.status || 500, 'error creating bottle'
      next()


  # returns bottle for given id
  @get: (req, res, next) ->
    bid = req.params.id
    Bottle.findById bid
    .then (bottle) ->
      if !bottle?
        res.send 404, "bottle `#{bid}` not found"
        return next()
      res.send 200, bottle
      return next()
    .catch (err) ->
      logger.error new VError 'Error finding bottle `%s`', bid
      res.send 500, 'Error finding bottle'
      return next()


  # returns all bottles that satisfy the given parameters
  @find = (req, res, next) ->
    bottleSrv.find req.params.appellation, req.params.producer, req.params.name, parseInt(req.params.year, 10)
    .then (bottles) ->
      if !bottles? || bottles.length == 0
        res.send 404, 'bottle not found'
        return next()

      res.send 200, bottles
      return next()
    .catch (err) ->
      logger.error new VError err, 'error finding bottle'
      res.send 500, 'error finding bottle'
      return next()


module.exports = exports = BottleController
