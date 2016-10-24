moment = require 'moment'
mongoose = require 'mongoose'

appellationSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  name: String
  stdForm: String # standardized form of the name

# Save hook: updates version and timestamp
appellationSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

Appellation = mongoose.model 'Appellation', appellationSchema

module.exports = exports = Appellation
