moment = require 'moment'
mongoose = require 'mongoose'

producerSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  name: String

# Save hook: updates version and timestamp
producerSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

Producer = mongoose.model 'Producer', producerSchema
module.exports = exports = Producer
