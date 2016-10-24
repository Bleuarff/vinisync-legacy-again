moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'cepageController'
utils = require '../utils/utils.js'
Cepage = require '../models/cepage.js'
normalizer = require '../services/normalizer.js'

class CepageController

  @index: (req, res, next) ->
    filter = {}

    if req.params.name?
      normValue = normalizer.getStandardForm req.params.name
      filter.stdForm = new RegExp "^#{normValue}", 'i'

    Cepage.find filter
    .sort {name: 1}
    .limit 10
    .then (data) ->
      cepages = data.map (x) -> return x.name
      res.send 200, cepages
      return next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving cepages'
      res.send 500, "Error retrieving cepages"
      return next()

module.exports = exports = CepageController
