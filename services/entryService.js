'use strict'

const VError = require('verror'),
      db = require('node-db-connector'),
      moment = require('moment'),
      ObjectId = require('bson-objectid')

class EntryService{

  // first retrieve the entry and check bottle count does not go below 0.
  static async decrementEntry(id, step, uid){
    try{
      var entry = await db.vni.collection('entries').findOne({_id: id, userId: uid})
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

  // build query object for entry list
  static buildFilters(params){
    var filters = {userId: new ObjectId(params.uid)}

    if (params.appellation)
      filters['wine.appellation'] = new RegExp(params.appellation, 'i')
    if (params.producer)
      filters['wine.producer'] = new RegExp(params.producer, 'i')
    if (params.year)
      filters['wine.year'] = parseInt(params.year, 10)
    if (params.color)
      filters['wine.color'] = params.color
    if (params.apogee){
      let apogee = parseInt(params.apogee, 10)
      // apogee: must be between start and end, or must be equal to start or end
      // TODO: (??) logic to check
      filters.$or = [{
        $and: [
          {"wine.apogeeStart": {$lte: apogee}},
          {"wine.apogeeEnd": {$gte: apogee}}
        ]},
        {"wine.apogeeStart": apogee},
        {"wine.apogeeEnd": apogee}
      ]
    }
    return filters
  }
}

module.exports = exports = EntryService
