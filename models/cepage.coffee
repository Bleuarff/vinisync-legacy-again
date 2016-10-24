moment = require 'moment'
mongoose = require 'mongoose'

cepageSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  name: String
  stdForm: String # standardized form of the name

# Save hook: updates version and timestamp
cepageSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

Cepage = mongoose.model 'Cepage', cepageSchema
module.exports = exports = Cepage
