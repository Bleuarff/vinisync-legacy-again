moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'userService'
Bottle = require '../models/bottle.js'

class BottleService

  @mandatoryFields = ['appellation', 'producer', 'year']

  # checks mandatory parameters are here
  @validate: (bottle) ->
    if !bottle?
      throw new VError 'missing param bottle'

    for f in BottleService.mandatoryFields
      if !bottle[f]?
        throw new VError 'missing params %s', f

    if typeof bottle.year != 'number' || bottle.year < 1800 || bottle.year > 2100
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
    bottle.cepages = bottle.cepages || []
    bottle.createDate = bottle.updateDate = moment.utc()
    return bottle.save()

module.exports = exports = BottleService
