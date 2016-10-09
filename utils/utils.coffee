crypto = require 'crypto'
VError = require 'verror'
moment = require 'moment'

# this module is loaded by the function that needs it, so as to avoid loading
# backoffice-specific module in this generic utility module.
accessEnum = null

# Contains miscellaneous utility methods
class Utils

  # checks the required parameters are in the request. Otherwise returns a 400 status
  # Also performs horizontal privilege escalation check
  # @params: param name or array of param names to check
  # @includeUid (default: true): whether to check for the uid parameter
  @hasParams = (req, res, params, includeUid = true) ->
    ok = true
    # mandatory parameter (in most cases)
    pList = if includeUid then ['uid'] else []
    if typeof params is 'string'
      pList.push params
    else if Array.isArray params
      pList = pList.concat params

    for p in pList
      if !req.params[p]?
        res.send 400, 'missing parameters'
        ok = false
        break

    # horizontal privilege escalation check
    if ok && (includeUid || !Utils.isNullOrEmpty(req.params.uid)) && req.params.uid != req.session.data.uid
      res.send 403, 'forbidden'
      ok = false

    return ok

  # checks the user has rights on the given application.
  # Checks the user session contains the request's appId & the requested access level
  # @req: request object
  # @res: response object
  # @accessLvl: access level to check (integer). Defaults to accessEnum.READ
  # @appIds: array of appIds to check. Defaults to req.params.appId
  @hasAppAccess = (req, res, accessLvl, appIds = [req.params.appId]) ->
    if !accessEnum?
      accessEnum = require '../lib/backoffice/models/accessEnum.js'

    if !accessLvl?
      accessLvl = accessEnum.READ

    if !Array.isArray appIds
      appIds = [appIds]

    granted = true
    for appId in appIds
      permissions = req.session.data[appId] || 0
      if (permissions & accessLvl) != accessLvl
        granted = false
        break

    if !granted
      res.send 403, 'access level not granted'
    return granted

  # Returns a deep copy of the object
  # @o: object to copy
  # @ignore: array of string: properties to no copy
  @copy = (o, ignore) ->
    if Array.isArray o
      c = []
      for e in o
        c.push Utils.copy e, ignore
      return c
    else if typeof o == "object"
      if o == null
        return null

      c = {}
      keys = Object.keys o
      for k in keys
        if typeof ignore == "undefined" || ignore is null || ignore.indexOf(k) is -1
          c[k] = Utils.copy o[k], ignore
      return c
    else
      return o

  # Returns true if the value is either null, undefined, or empty string
  # @value: string to test
  @isNullOrEmpty = (value) ->
    return !value? || value == ''

  # Returns true if the value is a valid email (RFC 5322 Official Standard)
  @isValidEmail = (value) ->
    regex = /^(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/i
    return regex.test(value)

  # Generates a random binary buffer and serializes it in base64
  # @length: length of the buffer to create. Resulting string is longer due to base64 encoding.
  @generateUniqueToken = (length = 24) ->
    promise = new Promise (resolve, reject) ->
      crypto.randomBytes length, (err, buf) ->
        if err
          reject err
          return
        else
          token = buf.toString 'base64'
          resolve token
    return promise

  # Waits for all promises to complete (resolve or reject) before resolving.
  # Taken from https://gist.github.com/peisenmann/41488a45364974705cd6
  # @promises: array of Promise objects
  @allComplete = (promises) ->
    return new Promise (resolve) ->
      retVals = new Array(promises.length)
      states = new Array(promises.length)
      for i in [0...promises.length]
        retVals[i] = states[i] = false

        f = (i) ->
          return (res) ->
            retVals[i] = res
            states[i] = true
            if (states.every (s) -> return s)
              resolve(retVals)

      promises.forEach (p, i) ->
        Promise.resolve(p).then(f(i), f(i))

  # Whether the given url path can be accessed without authentication
  # @path: request path
  # @publicUrls: array of string or regex for all public urls in the application
  @isPublic = (path, publicUrls) ->
    res = false
    i = 0
    while !res && i < publicUrls.length
      if typeof publicUrls[i].test == 'function'
        res = publicUrls[i].test path
      else
        res = path == publicUrls[i]
      i++

    return res

module.exports = exports = Utils
