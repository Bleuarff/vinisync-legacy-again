'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('entryController'),
      db = require('node-db-connector'),
      moment = require('moment'),
      ObjectId = require('bson-objectid'),
      utils = require('../../utils/utils.js'),
      wineSrv = require('../../services/wineService.js'),
      normalizer = require('../../services/normalizer.js'),

      collName = 'entries'

class EntryController {

  static async index(req, res, next){

    // TODO: filters
    var filters = {userId: new ObjectId(req.params.uid)}

    try {
      var entries = await db.vni.collection(collName).find(filters).toArray()
      res.send(200, entries)
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Error getting entries'))

      res.send(err.status || 500, 'Error getting entries')
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
          userId = new ObjectId(req.params.uid),
          query = {
            userId: userId,
            'wine.appellation': wine.appellation,
            'wine.producer': wine.producer,
            'wine.name': wine.name
          },
          status = 200, // default status
          entry = await db.vni.collection('entries').findOne(query)

      if (entry){
        // update entry if found
        let confirm = await db.vni.collection('entries').findOneAndUpdate({_id: entry._id}, {
          $inc: {count: count},
          $set: {
            updateDate: moment.utc().toDate()
          }
        },{
          returnOriginal: false
        })

        entry = confirm.value
        logger.debug('entry updated')
      }
      else{
        // otherwise create new entry
        let now = moment.utc().toDate()
        entry = {
          _id: new ObjectId(),
          wine: wine,
          userId: userId,
          count: req.params.count,
          offeredBy: req.params.offeredBy,
          createDate: now,
          updateDate: now
        }
        await db.vni.collection('entries').insertOne(entry)
        status = 201
        logger.debug('entry created')
      }

      res.send(status, entry)
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Error creating entry'))
      res.send(err.status || 500, err.status ? err.message : 'Error creating entry')
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
      let entry, id = ObjectId(req.params.id)
      if (step < 0)
        entry = await wineSrv.decrementEntry(id, step)
      else {
        let confirm = await db.vni.collection('entries').findOneAndUpdate({_id: id}, {
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
