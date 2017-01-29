moment = require 'moment'
mongoose = require 'mongoose'
ObjectId = mongoose.Schema.Types.ObjectId

# Entry model
entrySchema = new mongoose.Schema
  userId: ObjectId
  wine: { # full denormalization!
    appellation: String
    producer: String
    name: String
    year: Number
    cepages: [String]
    pictures: [String]
    apogeeStart: Number
    apogeeEnd: Number
    country: String
    color: String
    containing: String
    sweet: Boolean
    sparkling: Boolean
  }
  count: Number
  offeredBy: String
  location: String
  createDate: Date
  updateDate: Date

# Removes sensitive and uneeded fields on serialization
entrySchema.set 'toJSON', transform: (doc, ret, options) ->
  delete ret.__v
  return ret

# Save hook: updates version and timestamp
entrySchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

# update hook
entrySchema.pre 'update', () ->
  this.update {}, {
    $inc: {__v: 1}
    $set: {updateDate: moment.utc()}
  }

Entry = mongoose.model 'Entry', entrySchema, 'entries'
module.exports = exports = Entry
