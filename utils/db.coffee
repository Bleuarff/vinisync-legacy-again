VError = require 'verror'
mongoose = require 'mongoose'

config = require './config.js'
logger = require('./logger.js').create 'db'

# Handles Mongo connection
class Db

  @init: () ->
    mongoose.Promise = global.Promise # tells mongoose to use native Promise
    mongoose.connect config.db
    mongoosedb = mongoose.connection

    return new Promise (resolve, reject) ->
      # custom timeout when mongoose doesn't raise an error at all
      tm = setTimeout () ->
        reject new VError 'Mongoose connection error'
      , 60 * 1000

      mongoosedb.on 'error', (err) ->
        clearTimeout tm
        reject new VError err, 'Mongoose connection error'

      mongoosedb.once 'open', () ->
        logger.info 'Mongoose connection OK'
        clearTimeout tm
        resolve()

  # Closes DB connection
  @close: () ->
    return new Promise (resolve, reject) ->
      mongoose.disconnect (err) ->
        if err?
          logger.error new VError err, 'Mongoose connection close error'
        else
          logger.debug 'Mongoose connection closed'
        resolve()

module.exports = exports = Db
