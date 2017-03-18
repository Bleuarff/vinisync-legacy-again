moment = require 'moment'
mongoose = require 'mongoose'
ObjectId = mongoose.Schema.Types.ObjectId

# User model
userSchema = new mongoose.Schema
  createDate: Date
  updateDate: Date
  email: String
  name: String
  pwd: String
  enabled: Boolean
  confirmed: Boolean

  # TODO: store last login

# Removes sensitive and uneeded fields on serialization
userSchema.set 'toJSON', transform: (doc, ret, options) ->
  delete ret.pwd
  delete ret.__v
  return ret

# Save hook: updates version and timestamp
userSchema.pre 'save', (next) ->
  this.increment()
  this.updateDate = moment.utc()
  next()

# update hook
userSchema.pre 'update', () ->
  this.update {}, {
    $inc: {__v: 1}
    $set: {updateDate: moment.utc()}
  }

User = mongoose.model 'User', userSchema

module.exports = exports = User
