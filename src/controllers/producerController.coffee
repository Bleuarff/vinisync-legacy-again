moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'producerController'
utils = require '../utils/utils.js'
Producer = require '../models/producer.js'
normalizer = require '../services/normalizer.js'

class ProducerController

  @index: (req, res, next) ->
    filter = {}

    if req.params.name?
      normValue = normalizer.getStandardForm req.params.name
      filter.stdForm = new RegExp "#{normValue}", 'i'

    Producer.find filter
    .sort {name: 1}
    .limit 10
    .then (data) ->
      producers = data.map (x) -> return x.name
      res.send 200, producers
      return next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving producers'
      res.send 500, "Error retrieving producers"
      return next()

module.exports = exports = ProducerController
