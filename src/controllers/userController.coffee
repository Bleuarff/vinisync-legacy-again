class UserController

  @get = (req, res, next) ->
    res.send 400
    next()

module.exports = exports = UserController
