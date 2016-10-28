moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'wineService'
utils = require '../utils/utils.js'
Appellation = require '../models/appellation.js'
Wine = require '../models/wine.js'
Cepage = require '../models/cepage.js'
Producer = require '../models/producer.js'
normalizer = require './normalizer.js'

class WineService

  @mandatoryFields = ['appellation', 'producer']

  # checks mandatory parameters are here
  @validate: (wine) ->
    if !wine?
      throw new VError 'missing param wine'

    for f in WineService.mandatoryFields
      if !wine[f]? || wine[f] == ''
        throw utils.error null, "missing params #{f}", 400

    if wine.year && (typeof wine.year != 'number' || wine.year < 1800 || wine.year > 2100)
      throw utils.error null, 'year must be an integer between 1800 and 2100', 400
    return true


  # returns wines that match the given criteria
  @find: (appellation, producer, name, year) ->
    # text index includes all text fields (appellation, producer, name). A search can match results from any of these fields.
    terms = []
    if appellation
      terms.push "\"#{appellation}\""
    if producer
      terms.push "\"#{producer}\""
    if name
      terms.push "\"#{name}\""

    query = {}
    if terms.length > 0
      query.$text = { $search: terms.join ' ' }
    if year
      query.year = year
    return Wine.find query


  # creates a new wine
  @create: (params) ->
    wine = new Wine params
    wine.createDate = wine.updateDate = moment.utc()
    return wine.save()


  # propagates data after creating a cave entry
  # creates a wine and corresponding cepages, appellation and producer from a cave entry
  @propagate: (params) ->
    wine = params.toJSON()
    prms = []
    # propagate wine info
    # checks if wine exists before creating duplicate
    prms.push( WineService.find wine.appellation, wine.producer, wine.name, wine.year
    .then (wines) ->
      if wines.length == 0
        logger.debug 'wine not found, create'
        return WineService.create wine
      else
        logger.debug 'wine found, no update'
        return Promise.resolve()
    )

    # propagate appellation
    stdApp = normalizer.getStandardForm wine.appellation
    prms.push(Appellation.findOne {stdForm: stdApp}
    .then (app) ->
      if !app?
        logger.debug "appellation #{wine.appellation} not found"
        return Appellation.create {name: wine.appellation, stdForm: stdApp, createDate: moment.utc()}
      else
        logger.debug 'appellation found'
        return Promise.resolve()
    )

    stdPrd = normalizer.getStandardForm wine.producer
    prms.push(Producer.findOne {stdForm: stdPrd}
    .then (producer) ->
      if !producer?
        logger.debug "producer #{wine.producer} not found"
        return Producer.create {name: wine.producer, stdForm: stdPrd, createDate: moment.utc()}
      else
        logger.debug 'producer found'
        return Promise.resolve()
    )

    # propagate cepages sequentially
    cpgPrm = wine.cepages.reduce (prom, cpg) ->
      stdCpg = normalizer.getStandardForm cpg
      return Cepage.findOne {stdForm: stdCpg}
      .then (cepage) ->
        if !cepage?
          logger.debug "cepage #{cpg} not found"
          return Cepage.create {name: cpg, stdForm: stdCpg, createDate: moment.utc()}
        else
          logger.debug 'cepage found'
          return Promise.resolve()
    , Promise.resolve()
    prms.push cpgPrm

    return Promise.all prms

module.exports = exports = WineService
