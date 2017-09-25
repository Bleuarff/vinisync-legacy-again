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
}

module.exports = exports = WineService
