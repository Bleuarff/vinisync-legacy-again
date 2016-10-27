moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'wineController'
utils = require '../utils/utils.js'
Wine = require '../models/wine.js'
wineSrv = require '../services/wineService.js'
normalizer = require '../services/normalizer.js'

class WineController

  # Warning: creates duplicates, no first check
  @create = (req, res, next) ->
    try
      wineSrv.validate req.params.wine
    catch ex
      res.send 400, ex.message
      return next()

    wine = normalizer.normalize req.params.wine
    wineSrv.create wine
    .then (b) ->
      res.send 201, b
      next()
    .catch (err) ->
      logger.error new VError 'Error creating wine'
      res.send err.status || 500, 'error creating wine'
      next()


  # returns wine for given id
  @get: (req, res, next) ->
    wid = req.params.id
    Wine.findById wid
    .then (wine) ->
      if !wine?
        res.send 404, "wine `#{wid}` not found"
        return next()
      res.send 200, wine
      return next()
    .catch (err) ->
      logger.error new VError 'Error finding wine `%s`', wid
      res.send 500, 'Error finding wine'
      return next()


  # returns all wines that satisfy the given parameters
  @find = (req, res, next) ->
    wineSrv.find req.params.appellation, req.params.producer, req.params.name, parseInt(req.params.year, 10)
    .then (wines) ->
      if !wines? || wines.length == 0
        res.send 404, 'wine not found'
        return next()

      res.send 200, wines
      return next()
    .catch (err) ->
      logger.error new VError err, 'error finding wine'
      res.send 500, 'error finding wine'
      return next()


module.exports = exports = WineController
