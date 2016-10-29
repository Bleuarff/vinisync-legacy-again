moment = require 'moment'
mongoose = require 'mongoose'

wineSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  appellation: String
  producer: String
  name: String
  year: Number
  cepages: [String]
  pictures: [String]

# Save hook: updates version and timestamp
wineSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

Wine = mongoose.model 'Wine', wineSchema

module.exports = exports = Wine
