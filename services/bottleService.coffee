moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'userService'
Appellation = require '../models/appellation.js'
Bottle = require '../models/bottle.js'
Cepage = require '../models/cepage.js'
Producer = require '../models/producer.js'
normalizer = require './normalizer.js'

class BottleService

  @mandatoryFields = ['appellation', 'producer']

  # checks mandatory parameters are here
  @validate: (bottle) ->
    if !bottle?
      throw new VError 'missing param bottle'

    for f in BottleService.mandatoryFields
      if !bottle[f]? || bottle[f] == ''
        throw new VError 'missing params %s', f

    if bottle.year && (typeof bottle.year != 'number' || bottle.year < 1800 || bottle.year > 2100)
      throw new VError 'year must be an integer between 1800 and 2100'
    return true


  # returns bottles that match the given criteria
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
    return Bottle.find query


  # creates a new bottle
  @create: (params) ->
    bottle = new Bottle params
    # bottle.cepages = bottle.cepages || []
    bottle.createDate = bottle.updateDate = moment.utc()
    return bottle.save()


  # propagates data after creating a cave entry
  # creates a bottle and corresponding cepages, appellation and producer from a cave entry bottle
  @propagate: (params) ->
    bottle = params.toJSON()
    prms = []
    # propagate bottle
    # checks if bottle exists before creating duplicate
    prms.push( BottleService.find bottle.appellation, bottle.producer, bottle.name, bottle.year
    .then (bottles) ->
      if bottles.length == 0
        logger.debug 'bottle not found, create'
        return BottleService.create bottle
      else
        logger.debug 'bottle found, no update'
        return Promise.resolve()
    )

    # propagate appellation
    stdApp = normalizer.getStandardForm bottle.appellation
    prms.push(Appellation.findOne {stdForm: stdApp}
    .then (app) ->
      if !app?
        logger.debug "appellation #{bottle.appellation} not found"
        return Appellation.create {name: bottle.appellation, stdForm: stdApp, createDate: moment.utc()}
      else
        logger.debug 'appellation found'
        return Promise.resolve()
    )

    stdPrd = normalizer.getStandardForm bottle.producer
    prms.push(Producer.findOne {stdForm: stdPrd}
    .then (producer) ->
      if !producer?
        logger.debug "producer #{bottle.producer} not found"
        return Producer.create {name: bottle.producer, stdForm: stdPrd, createDate: moment.utc()}
      else
        logger.debug 'producer found'
        return Promise.resolve()
    )

    # propagate cepages sequentially
    cpgPrm = bottle.cepages.reduce (prom, cpg) ->
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

module.exports = exports = BottleService
