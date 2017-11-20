'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('appellationController'),
      db = require('node-db-connector'),
      normalizer = require('../../services/normalizer.js'),

      collName = 'appellations'


class AppellationController{

  static async index(req, res, next){
    var filters = {}

    if (req.params.term != null){
      let stdForm = normalizer.getStandardForm(req.params.term)
      filters.stdForm = new RegExp(`^${stdForm}`, 'i')
    }

    try{
      let appellations = await db.vni.collection(collName).find(filters, {name: 1}).sort({stdForm: 1}).toArray()
      res.send(200, appellations)
      return next()
    }
    catch(err){
      logger.error(new VError(err, 'Error retrieving appellations for term %s', req.params.term))
      res.send(500, 'error retrieving appellations')
      return next(false)
    }
  }
}

module.exports = exports = AppellationController
