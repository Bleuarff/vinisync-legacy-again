'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('wineService'),
      utils = require('../utils/utils.js'),
      db = require('node-db-connector'),
      moment = require('moment'),
      normalizer = require('./normalizer.js')

const mandatoryFields = ['appellation', 'producer'],
      yearFields = ['year', 'apogeeStart', 'apogeeEnd']

class WineService {

  static validate(wine){
    if (wine == null)
      throw new VError('missing param wine')

    mandatoryFields.forEach(f => {
      if (wine[f] == null || wine[f] === '')
        throw utils.error(`missing param ${f}`, 400)
    })

    try{
      yearFields.forEach(f => {
        WineService.checkYear(wine[f])
      })
    }
    catch(err){
      throw utils.error('invalid param', 400, err)
    }

    return wine
  }

  // checks that if provided, the value must be a number in valid range
  static checkYear(value){
    if (value && (typeof value !== 'number' || value < 1800 || value > 2100))
      throw new VError('invalid value')
  }

  static buildFindQuery(wine){
    // text index includes all text fields (appellation, producer, name). A search can match results from any of these fields.
    var terms = [],
        query = {}

    if (wine.appellation)
      terms.push(`"${wine.appellation}"`)
    if (wine.producer)
      terms.push(`"${wine.producer}"`)
    if (wine.name)
      terms.push(`"${wine.name}"`)

    if (terms.length > 0)
      query.$text = {$search: terms.join(' ')}
    if (wine.year)
      query.year = wine.year

    return query
  }

  // search for wine. If not found, create it
  static createWine(wine){
    var query = WineService.buildFindQuery(wine)
    wine.createDate = moment.utc().toDate()
    return db.vni.collection('wines').findOneAndUpdate(query, {
      $setOnInsert: wine
    }, {upsert: true, returnOriginal: false})
    .catch(err => {
      throw new VError(err, 'Error creating wine')
    })
  }

  // inserts a new document in given collection, with value name.
  // Also inserts standard form value. Used for all "simple" collections
  static createEntity(value, collName){
    var stdForm = normalizer.getStandardForm(value)
    return db.vni.collection(collName).findOneAndUpdate({stdForm: stdForm}, {
      $setOnInsert: {name: value, stdForm: stdForm, createDate: moment.utc().toDate()}
    }, {upsert: true, returnOriginal: false})
    .catch(err => {
      throw new VError(err, 'Error propagating value %s in %s', value, collName)
    })
  }

  // data propagation: when a new entry is created, we also create a corresponding wine document
  // Same for producer, appellation and cepages, to have a list of possible values
  static propagate(wine){
    var proms = []
    proms.push(WineService.createWine(wine))
    proms.push(WineService.createEntity(wine.appellation, 'appellations'))
    proms.push(WineService.createEntity(wine.producer, 'producers'))

    if (wine.cepages){
      wine.cepages.forEach(cepage => {
        proms.push(WineService.createEntity(cepage, 'cepages'))
      })
    }

    return Promise.all(proms)
    .then(() => Promise.resolve())
    .catch(err => {
      logger.error(err, 'Propagation error')
      return Promise.resolve()
    })
  }
}

module.exports = exports = WineService
