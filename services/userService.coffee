moment = require 'moment'
VError = require 'verror'
logger = require('../utils/logger.js').create 'userService'
User = require '../models/user.js'

class UserService

  @load: (uid) ->
    if !uid? || uid == ''
      err = new VError "missing parameter uid"
      err.status = 400
      throw error

    User.findById uid
    .then (user) ->
      if !user?
        err = new VError "user #{uid} not found"
        err.status = 404
        throw err

      logger.debug "user: #{user.name}"
      return Promise.resolve user

  # updates entry count by the given increment
  @updateEntryCount: (caveId, entryId, increment) ->
    User.update {_id: caveId, 'bottles._id': entryId}, {
      $inc: {'bottles.$.count': increment}
      $set: {'bottles.$.updateDate': moment.utc()}
    }
    .then (r) ->
      # resolves with wether a match was found and updated
      return Promise.resolve(r.nModified == 1)
    .catch (err) ->
      throw new VError err, 'Error updating entry counter for bottle %s in cave %s', entryId, caveId

module.exports = exports = UserService
