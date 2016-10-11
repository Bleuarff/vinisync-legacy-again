moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'bottleController'
utils = require '../utils/utils.js'
Bottle = require '../models/bottle.js'

class BottleController

  @create = (req, res, next) ->
    if !utils.hasParams req, res, 'bottle', false
      return next()

    # validation
    mandatoryFields = ['appellation', 'domain', 'year']
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

module.exports = exports = BottleController
