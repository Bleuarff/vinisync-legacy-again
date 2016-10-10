crypto = require 'crypto'
VError = require 'verror'

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
    return value.contains '@'

  # Generates a random binary buffer and serializes it in base64
  # @length: length of the buffer to create. Resulting string is longer due to base64 encoding.
  @generateUniqueToken = (length = 24) ->
    return new Promise (resolve, reject) ->
      crypto.randomBytes length, (err, buf) ->
        if err
          reject err
          return
        else
          token = buf.toString 'base64'
          resolve token

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
