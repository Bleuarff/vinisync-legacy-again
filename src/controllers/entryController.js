'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('entryController'),
      db = require('node-db-connector'),
      moment = require('moment'),
      ObjectId = require('bson-objectid'),
      utils = require('../../utils/utils.js'),

      collName = 'entries'

class EntryController {

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
}

module.exports = exports = EntryController