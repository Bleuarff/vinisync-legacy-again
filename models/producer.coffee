moment = require 'moment'
mongoose = require 'mongoose'

producerSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  name: String
  stdForm: String # standardized form of the name

# Save hook: updates version and timestamp
producerSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

Producer = mongoose.model 'Producer', producerSchema
module.exports = exports = Producer
