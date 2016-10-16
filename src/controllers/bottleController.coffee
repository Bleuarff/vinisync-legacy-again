moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'bottleController'
utils = require '../utils/utils.js'
Bottle = require '../models/bottle.js'
bottleSrv = require '../services/bottleService.js'

class BottleController

  @create = (req, res, next) ->
    if !utils.hasParams req, res, 'bottle', false
      return next()

    # validation
    mandatoryFields = ['appellation', 'producer', 'year']
    for f in mandatoryFields
      if !req.params.bottle[f]?
        logger.debug "f:" + f + ' v:' + req.params.bottle[f]
        res.send 400, "missing param '#{f}'"
        return next()

    bottle = new Bottle req.params.bottle
    bottle.cepages = bottle.cepages || []
    bottle.createDate = bottle.updateDate = moment.utc()
    bottle.save()
    .then (b) ->
      res.send 201, b
      next()
    .catch (err) ->
      logger.error new VError 'Error creating bottle'
      res.send 500, 'error creating bottle'
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
