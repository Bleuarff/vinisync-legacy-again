moment = require 'moment'
mongoose = require 'mongoose'

cepageSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  name: String

# Save hook: updates version and timestamp
cepageSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

Cepage = mongoose.model 'Cepage', cepageSchema, 'cepages'
module.exports = exports = Cepage
