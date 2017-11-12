'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('wineService'),
      utils = require('../utils/utils.js'),
      db = require('node-db-connector'),
      moment = require('moment'),
      ObjectId = require('bson-objectid'),
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

  static async updateWine(oldWine, newWine){
    if (typeof oldWine != 'object')
      throw new Error('wine: invalid type')
    else if (!oldWine)
      throw new Error('Cannot look for null wine')

    var query = {appellation: oldWine.appellation, producer: oldWine.producer},
        fields = ['name', 'year', 'country', 'apogeeStart', 'apogeeEnd', 'color', 'cepages', 'containing', 'sweet', 'sparkling'],
        now = moment.utc().toDate()

    // null/undefined fields are replaced with null. In mongodb query, null means null or undefined
    fields.forEach(f => {
      if (oldWine[f] || typeof oldWine[f] === 'boolean')
        query[f] = oldWine[f]
      else {
        query[f] = null
      }
    })

    newWine.updateDate = now

    try{
      // first look for document, then update/upsert new values
      let w = await db.vni.collection('wines').findOne(query),
          id = w ? w._id : ObjectId()

      await db.vni.collection('wines').updateOne({_id: id}, {
        $set: newWine,
        $setOnInsert: {createDate: now}
      }, {upsert: true})
    }
    catch(err){
      throw new VError(err, 'Error updating wine')
    }
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

  // data propagation: when a new entry is created or updated, we also create/update a corresponding wine document
  // Same for producer, appellation and cepages, to have a list of possible values
  static propagate(wine, oldWine = null){
    var proms = []
    if (oldWine)
      proms.push(WineService.updateWine(oldWine, wine))
    else
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

  static isEqual(w1, w2){
    if (!w1 || !w2)
      return false

    // appellation, producer must be equal and not null/undefined/empty
    if (w1.appellation !== w2.appellation || !w1.appellation || w1.producer !== w2.producer || !w1.producer)
      return false

    var ident = true

    // these properties must be equal OR both null/undefined/empty
    var props = ['name', 'year', 'country', 'apogeeStart', 'apogeeEnd', 'containing', 'color']
    for (let i = 0; i < props.length; i++){
      let p = props[i]
      if (w1[p] !== w2[p] && (w1[p] != null || w2[p] != null)){
        ident = false
        break
      }
    }

    if (!ident)
      return false

    // one cepage is null/undef and not the other -> fail
    if (w1.cepages == null && w2.cepages != null || w1.cepages != null && w2.cepages == null)
      return false

    // checks cepage arrays contain the same values, even if not in the same order
    if (w1.cepages != null && w2.cepages != null){
      if (w1.cepages.length !== w2.cepages.length)
        return false

      for (let i = 0; i < w1.cepages.length; i++){
        let cepage = w1.cepages[i]
        if (w2.cepages.indexOf(cepage) === -1){
          ident = false
          break
        }
      }
      if (!ident)
        return false
    }

    // details fields
    ['sweet', 'sparkling'].forEach(x => {
      let p1 = w1[x], p2 = w2[x]

      if ((typeof p1 !== 'boolean' && p1 != null) || (typeof p2 !== 'boolean' && p2 != null))
        ident = false // incorrect type for p1 or p2
      else if (!p1 !== !p2) // value mismatch
        ident = false
    })

    return ident
  }
}

module.exports = exports = WineService
