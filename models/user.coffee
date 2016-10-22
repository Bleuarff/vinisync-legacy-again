moment = require 'moment'
mongoose = require 'mongoose'
ObjectId = mongoose.Schema.Types.ObjectId

# User model
userSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  name: String
  email: String
  bottles: [{
    bottle: { # full denormalization!
      appellation: String
      producer: String
      name: String
      year: Number
      cepages: [String]
    }
    count: Number
    location: String
    createDate: Date
    updateDate: Date
  }]

# Removes sensitive and uneeded fields on serialization
userSchema.set 'toJSON', transform: (doc, ret, options) ->
  # delete ret.password
  delete ret.__v
  return ret

# Save hook: updates version and timestamp
userSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

User = mongoose.model 'User', userSchema

module.exports = exports = User
