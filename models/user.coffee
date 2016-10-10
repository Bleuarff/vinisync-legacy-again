moment = require 'moment'
mongoose = require 'mongoose'
ObjectId = mongoose.Schema.Types.ObjectId

# User model
userSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  name: String
  email: String
  cave: [{
      bottleId: ObjectId
      count: Number
      location: String
  }]

# Removes sensitive and uneeded fields on serialization
userSchema.set 'toJSON', transform: (doc, ret, options) ->
  delete ret.password
  delete ret.webcoupon
  delete ret.__v
  delete ret._id

# Save hook: updates version and timestamp
userSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

User = mongoose.model 'User', userSchema, 'users'

module.exports = exports = User
