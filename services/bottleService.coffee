moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'userService'
Bottle = require '../models/bottle.js'

class BottleService

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

module.exports = exports = BottleService
