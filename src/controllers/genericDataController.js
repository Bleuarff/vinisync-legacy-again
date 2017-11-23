'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('genericDataController'),
      db = require('node-db-connector'),
      normalizer = require('../../services/normalizer.js')

class GenericDataController{

  static async index(req, res, next){
    var collName = req.params[0],
        filters = {}

    // logger.debug('tap into collection ' + collName)

    if (req.params.search != null){
      let stdForm = normalizer.getStandardForm(req.params.search)
      filters.stdForm = new RegExp(stdForm)
    }

    try{
      let results = await db.vni.collection(collName).find(filters, {name: 1, stdForm: 1})
        .sort({stdForm: 1}).toArray()

      let data = results.map(a => {return {name: a.name, stdForm: a.stdForm}})
      res.send(200, data)
      return next()
    }
    catch(err){
      logger.error(new VError(err, 'Error retrieving %s for query %s', collName, req.params.search))
      res.send(500, `error retrieving ${collName}`)
      return next(false)
    }
  }
}

module.exports = exports = GenericDataController
