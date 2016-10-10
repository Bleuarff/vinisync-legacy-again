moment = require 'moment'
mongoose = require 'mongoose'

bottleSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  appellation: String
  domain: String
  name: String
  year: Number
  cepages: [String]

# Save hook: updates version and timestamp
bottleSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

Bottle = mongoose.model 'Bottle', bottleSchema, 'bottles'

module.exports = exports = Bottle
