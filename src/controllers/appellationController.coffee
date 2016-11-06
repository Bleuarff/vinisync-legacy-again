moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'appellationController'
utils = require '../utils/utils.js'
Appellation = require '../models/appellation.js'
normalizer = require '../services/normalizer.js'

class AppellationController

  @index: (req, res, next) ->
    filter = {}

    if req.params.name?
      normValue = normalizer.getStandardForm req.params.name
      filter.stdForm = new RegExp "#{normValue}", 'i'

    Appellation.find filter
    .sort {name: 1}
    .limit 10
    .then (data) ->
      appellations = data.map (x) -> return x.name
      res.send 200, appellations
      return next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving appellations'
      res.send 500, "Error retrieving appellations"
      return next()

module.exports = exports = AppellationController
