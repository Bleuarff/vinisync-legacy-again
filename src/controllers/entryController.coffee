VError = require 'verror'
moment = require 'moment'
ObjectId = require('mongoose').Types.ObjectId
logger = require('../utils/logger.js').create 'entryController'
config = require '../utils/config.js'
utils = require '../utils/utils.js'
Entry = require '../models/entry.js'
wineSrv = require '../services/wineService.js'
normalizer = require '../services/normalizer.js'


class EntryController

  # retrieves all entries for a given user
  @index = (req, res, next) ->
    if !utils.hasParams req, res, []
      return next()

    try
      uid = new ObjectId req.params.uid
    catch err
      logger.error new VError err, 'Error casting into ObjectId'
      res.send 400, 'Error casting to ObjectId'
      return next()

    offset = parseInt(req.params.offset, 10) || 0
    pageCount = parseInt(req.params.count, 10) || 20
    totalCount = 0
    Entry.count {userId: uid}
    .then (count) ->
      totalCount = count
      Entry.find({userId: uid}).skip(offset).limit(pageCount)
    .then (entries) ->
      data =
        entryCount: totalCount
        bottles: entries

      res.send 200, data
      next()
    .catch (err) ->
      logger.error new VError 'Error retrieving bottles for user %s', uid
      res.send err.status || 500, 'Error retrieving bottles'
      next()


  # Retrieves a given entry
  @getEntry = (req, res, next) ->
    if !utils.hasParams req, res
      return next()

    try
      uid = new ObjectId req.params.uid
      entryId = new ObjectId req.params.entryId
    catch err
      logger.error new VError err, 'Error casting into ObjectId'
      res.send 400, 'Error casting to ObjectId'
      return next()

    Entry.findOne {_id: entryId, userId: uid}
    .then (entry) ->
      if !entry?
        res.send 404, "Entry not found"
      else
        res.send 200, entry
      return next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving entry %s', req.params.entryId
      res.send err.status || 500, 'Error retrieving entry'
      return next()


  # Returns the total number of bottles
  @getBottleCount: (req, res, next) ->
    if !utils.hasParams req, res, []
      return next()

    try
      uid = new ObjectId req.params.uid
    catch error
      res.send 400, 'uid is not an ObjectId'
      return next()

    Entry.aggregate()
    .match {userId: uid}
    .group {_id: '$userId', total: {$sum: '$count'}}
    .exec()
    .then (results) ->
      if results.length
        count = results[0].total
      else
        count = 0
      res.send 200, {count: count}
      next()
    .catch (err) ->
      logger.error new VError err, 'Error retrieving bottle count'
      res.send 500, 'Error retrieving bottle count'
      next()


  # adds an entry to the cave
  @addEntry = (req, res, next) ->
    if !utils.hasParams req, res, ['wine', 'count']
      return next()

    try
      uid = new ObjectId req.params.uid
    catch err
      res.send 400, 'userId is not an ObjectId'
      return next()

    try
      wineSrv.validate req.params.wine
    catch error
      # logger.info new VError error, "invalid wine parameters"
      res.send 400, error.message
      return next()

    wine = normalizer.normalize req.params.wine
    logger.debug "add to cave: #{wine.appellation}, #{wine.producer}, #{wine.name}, #{wine.year} / count: #{req.params.count}"

    # checks if an entry already exists
    Entry.findOne {
      userId: uid
      'wine.appellation': wine.appellation
      'wine.producer': wine.producer
      'wine.name': wine.name
      'wine.year': wine.year
    }
    .then (entry) ->
      # if so, update counter
      if entry?
        # TODO: if cepages provided and != from existing entry, update
        logger.debug "found entry, update"
        entry.count += req.params.count
        entry.updateDate = moment.utc()
      else
        # otherwise create new entry
        logger.debug 'entry not found, create'
        entry = new Entry {
          wine: wine
          userId: uid
          count: req.params.count
          offeredBy: req.params.offeredBy
          createDate: moment.utc()
          updateDate: moment.utc()
        }

      entry.save()
    .then (entry) ->
      res.send 200, entry

      # add to wine collection (and subsequently to appellation, producer, cepages collections)
      wineSrv.propagate entry.wine
      .then () ->
        return next()
      .catch (err) ->
        # on error, log but do not send error to client - wine has been added to the cave OK
        logger.error new VError err, 'Error creating wine'
        return next()
    .catch (err) ->
      logger.error new VError err, 'error adding wine to cave `%s`', id
      res.send 500, "Error adding wine"
      return next()


  # updates an entry with the given params
  @updateEntry = (req, res, next) ->
    if !utils.hasParams req, res, ['wine', 'count']
      return next()

    try
      uid = new ObjectId req.params.uid
      entryId = new ObjectId req.params.entryId
    catch ex
      res.send 400, 'invalid parameters'
      return next()

    try
      wineSrv.validate req.params.wine
    catch error
      logger.info new VError error, "invalid wine parameters"
      res.send 400, error.message
      return next()

    entry = null
    Entry.findOne {_id: entryId, userId: uid}
    .then (entry) ->
      if !entry?
        throw utils.error 'entry not found', 404

      update = normalizer.normalize req.params.wine

      # applies new values
      entry.wine.appellation = update.appellation
      entry.wine.producer = update.producer

      fields = ['name', 'year', 'cepages', 'country', 'apogeeStart', 'apogeeEnd', 'containing', 'color', 'sweet',
      'sparkling']
      for f in fields
        if update[f]?
          entry.wine[f] = update[f]

      if req.params.count?
        entry.count = req.params.count
      if req.params.offeredBy?
        entry.offeredBy = req.params.offeredBy

      entry.updateDate = moment.utc()
      entry.save()
    .then (entry) ->
      res.send 200, entry
      # add to wine collection (and subsequently to appellation, producer, cepages collections)
      wineSrv.propagate entry.wine
      .then () ->
        return next()
      .catch (err) ->
        # on error, log but do not send error to client - wine has been added to the cave OK
        logger.error new VError err, 'Error creating wine'
        return next()
    .catch (err) ->
      logger.error new VError err, 'Error updating entry %s for user %s', req.params.entryId, req.params.uid
      switch err.status
        when 400 then msg = 'invalid parameters'
        else msg = 'error updating entry'
      res.send err.status || 500, msg
      return next()


  # increments an entry count by 1
  @increment = (req, res, next) ->
    if !utils.hasParams req, res
      return next()

    try
      uid = new ObjectId req.params.uid
      entryId = new ObjectId req.params.entryId
    catch ex
      res.send 400, 'invalid parameters'
      return next()

    Entry.findOneAndUpdate {_id: entryId, userId: uid}, {
      $inc: {count: 1}
      $set: {updateDate: moment.utc()}
    }, {new: true}
    .then (entry) ->
      if !entry?
        res.send 404, 'entry not found'
      else
        res.send 200, {count: entry.count}
      return next()
    .catch (err) ->
      logger.error new VError 'Error incrementing entry %s for user %s', entryId, uid
      res.send 500, 'error incrementing entry count'
      return next()


  # decrements an entry count by 1
  # TODO: when 0, what ?
  @decrement = (req, res, next) ->
    if !utils.hasParams req, res
      return next()

    try
      uid = new ObjectId req.params.uid
      entryId = new ObjectId req.params.entryId
    catch ex
      res.send 400, 'invalid parameters'
      return next()

    Entry.findOneAndUpdate {_id: entryId, userId: uid}, {
      $inc: {count: -1}
      $set: {udpateDate: moment.utc()}
    }
    .then (entry) ->
      if !entry?
        throw utils.error 'entry not found', 404

      res.send 200, {count: entry.count}
      return next()
    .catch (err) ->
      logger.error new VError err,'Error decrementing entry  %s for user %s', entryId, uid
      res.send err.status || 500, 'error decrementing entry count'
      return next()

module.exports = exports = EntryController
