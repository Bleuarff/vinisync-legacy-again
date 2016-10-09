VError = require 'verror'

cookies = require './cookies.js'
logger =  require('./logger.js').create 'CSRF'
utils = require './utils.js'

class CSRF

  # list of cookies to delete when smth is wrong with the CSRF token
  @cookies = []
  @publicUrls = []

  # For any non-GET request, ensures the payload contains a CSRF token equals to the current one for the session.
  # If not found, destroys the session and returns an error.
  @checkToken = (req, res, next) ->
    # GET, non-authenticated requests and requests to public urls are not checked
    if req.method == 'GET' || !req.session.data.uid? || utils.isPublic(req.path(), CSRF.publicUrls)
      return next()

    clientToken = req.params.csrfToken
    if !clientToken?
      logger.error 'missing CSRF token at ' + req.path()
      res.send 400, {msg: 'err_missing_csrf'}
      CSRF.destroy req, res
      return next false

    if clientToken == req.session.data.csrfToken # all good
      return next()

    # Invalid token: possible attack. Delete session & cookies.
    logger.error 'invalid CSRF token at ' + req.path()
    CSRF.destroy req, res
    # for cName in CSRF.cookies
    #   cookies.delete res, cName

    res.send 401, {msg: 'err_invalid_csrf'}
    # req.session.destroy()
    next false

  # deletes cookies and kills session
  @destroy = (req, res) ->
    for cName in CSRF.cookies
      cookies.delete res, cName
    req.session.destroy()

module.exports = exports = CSRF
