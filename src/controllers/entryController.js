'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('entryController'),
      db = require('node-db-connector'),
      moment = require('moment'),
      ObjectId = require('bson-objectid'),
      utils = require('../../utils/utils.js'),
      wineSrv = require('../../services/wineService.js'),
      entrySrv = require('../../services/entryService.js'),
      normalizer = require('../../services/normalizer.js'),

      collName = 'entries'

class EntryController {

  static async index(req, res, next){

    // build filters object
    var filters = entrySrv.buildFilters(req.params),
        offset = parseInt(req.params.offset, 10) || 0,
        pageSize = parseInt(req.params.pageSize, 10) || 20

    try {
      let count = await db.vni.collection(collName).count(filters)
      let entries = await db.vni.collection(collName).find(filters).skip(offset).limit(pageSize).toArray()
      res.send(200, {entries: entries, count: count})
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Error getting entries'))

      res.send(err.status || 500, 'Error getting entries')
      return next(false)
    }
  }

  // use aggregation pipeline to count total number of bottles in all entries for user
  static async getBottleCount(req, res, next){
    if (!ObjectId.isValid(req.params.uid)){
      res.send(400, 'invalid uid')
      return next(false)
    }

    try{
      let results = await db.vni.collection(collName).aggregate([
        {$match: {userId: ObjectId(req.params.uid)}},
        {$group: {_id: '$userId', total: {$sum: '$count'}}}
      ]).toArray()

      let count = 0
      if (results.length)
        count = results[0].total

      res.send(200, {count: count})
      return next()
    }
    catch(err){
      logger.error(new VError(err, 'Error retrieving bottle count'))
      res.send(500, 'Error retrieving bottle count')
      return next(false)
    }
  }

  static async get(req, res, next){
    // no need for hasParams check - id is mandatory in url
    //  or checking uid is valid, it's already checked by a previous restify handler

    if (!ObjectId.isValid(req.params.id)){
      res.send(400, 'invalid id')
      return next(false)
    }

    try{
      var id = new ObjectId(req.params.id),
          uid = new ObjectId(req.params.uid),
          entry = await db.vni.collection(collName).findOne({_id: id})

      if (!entry)
        throw utils.error('Entry not found', 404)

      if (!entry.userId.equals(uid))
        throw utils.error('Forbidden', 403)

      res.send(200, entry)
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Error getting entry %s', req.params.id))

      res.send(err.status || 500, 'Error getting entry')
      return next(false)
    }
  }

  // creates an entry
  static async create(req, res, next){
    if (!utils.hasParams(res, req.params, ['wine', 'count']))
      return next(false)

    var count = parseInt(req.params.count, 10)
    if (isNaN(count)){
      res.send(400)
      return next(false)
    }

    try{
      wineSrv.validate(req.params.wine)
      let wine = normalizer.normalize(req.params.wine),
          now = moment.utc().toDate()

      let entry = {
        _id: ObjectId(),
        wine: wine,
        userId: ObjectId(req.params.uid),
        count: count,
        offeredBy: req.params.offeredBy,
        createDate: now,
        updateDate: now
      }
      await db.vni.collection(collName).insertOne(entry)
      logger.debug('entry created')

      res.send(201, entry)
      wineSrv.propagate(wine)
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Error creating entry'))
      res.send(err.status || 500, err.status ? err.message : 'Error creating entry')
      return next(false)
    }
  }

  // updates an entry
  static async update(req, res, next){
    if (!utils.hasParams(res, req.params, ['wine', 'count']))
      return next(false)

    if (!ObjectId.isValid(req.params.id)){
      res.send(400)
      return next(false)
    }

    var count = parseInt(req.params.count, 10)
    if (isNaN(count)){
      res.send(400)
      return next(false)
    }

    try{
      wineSrv.validate(req.params.wine)
      let wine = normalizer.normalize(req.params.wine),
          updateDate = moment.utc().toDate()
      let result = await db.vni.collection(collName).findOneAndUpdate({
        _id: ObjectId(req.params.id), userId: ObjectId(req.params.uid)
      }, {
        $set: {
          wine: wine,
          count: count,
          offeredBy: req.params.offeredBy,
          updateDate: updateDate
        }
      })

      // fail if document not found
      if (!result.value){
        res.send(404)
        return next(false)
      }

      let entry = result.value

      if (!wineSrv.isEqual(wine, entry.wine)){
        // entry has modified wine, find and update it
        try{
          await wineSrv.propagate(wine, result.value.wine)
        }
        catch(err){
          logger.error(new VError(err, 'error updating wine'))
        }
      }

      entry.wine = wine
      entry.count = count
      entry.offeredBy = req.params.offeredBy
      entry.updateDate = updateDate

      res.send(200, entry)
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Error updating entry %s', req.params.id))
      res.send(err.status || 500, err.status ? err.message : 'Error updating entry')
      return next(false)
    }
  }

  // updates bottle count
  static async increment(req, res, next){
    if (!utils.hasParams(res, req.params, 'step')){
      return next(false)
    }

    var step = parseInt(req.params.step, 10)
    if (isNaN(step)){
      res.send(400, 'invalid step')
      return next(false)
    }

    if (!ObjectId.isValid(req.params.id)){
      res.send(400, 'invalid entry id')
      return next(false)
    }

    try{
      // negative step: dedicated method to ensure bottle count does not go below 0
      let entry, id = ObjectId(req.params.id), uid = ObjectId(req.params.uid)
      if (step < 0)
        entry = await entrySrv.decrementEntry(id, step, uid)
      else {
        let confirm = await db.vni.collection(collName).findOneAndUpdate({_id: id, userId: uid}, {
          $inc: {count: step},
          $set: {update: moment.utc().toDate()}
        }, {returnOriginal: false})

        if (confirm.value == null){
          res.send(404, 'entry not found')
          return next(false)
        }
        entry = confirm.value
      }

      res.send(200, entry)
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'error increment entry %s', req.params.id))

      res.send(err.status || 500, "error incrementing entry count")
      return next(false)
    }
  }
}

module.exports = exports = EntryController
