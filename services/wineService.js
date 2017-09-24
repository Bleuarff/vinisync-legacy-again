'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('wineService'),
      utils = require('../utils/utils.js'),
      db = require('node-db-connector'),
      moment = require('moment')

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

  // first retrieve the entry and check bottle count does not go below 0.
  static async decrementEntry(id, step){
    try{
      var entry = await db.vni.collection('entries').findOne({_id: id})
      if (!entry)
        throw new VError('entry not found')

      let newCount = Math.max(entry.count + step, 0) // avoid negative bottle count
      let confirm = await db.vni.collection('entries').findOneAndUpdate({_id: id}, {
        $set: {
          count: newCount,
          updateDate: moment.utc().toDate()
        }
      }, {returnOriginal: false})

      entry = confirm.value
      return entry
    }
    catch(err){
      throw new VError(err, 'Error decrement entry %s', id)
    }
  }
}

module.exports = exports = WineService
