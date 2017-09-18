'use strict'

const VError = require('verror'),
      util = require('util'),
      crypto = require('crypto'),
      randomBytes = util.promisify(crypto.randomBytes)

class Utils {
  // checks the required parameters are in the request. Otherwise returns a 400 status
  // Also performs horizontal privilege escalation check
  // @params: param object from request
  // @expected: string or array of expected args
  static hasParams(res, params, expected){
    if (typeof expected === 'string' && expected.length > 0){
      return params[expected] != null
    }

    if (!Array.isArray(expected))
      throw new VError('invalid `expected` args')

    var allExist = expected.every(value => {
      return params[value] != null
    })

    if (!allExist){
      res.send(400, 'missing parameters')
      return false
    }

    return true
  }

  static error(message, status = 500, innerErr){
    var err
    if (innerErr)
      err = new VError(innerErr, message)
    else
      err = new VError(message)

    err.status = status
    return err
  }

  // Generates a random binary buffer and serializes it in base64
  // @length: length of the buffer to create. Resulting string is longer due to base64 encoding.
  static async generateUniqueToken(length = 24){
    try{
      let buf = await randomBytes(length),
          token = buf.toString('base64')
      return Promise.resolve(token)
    }
    catch(err){
      throw new VError(err, 'Error generating random token')
    }
  }
}
module.exports = exports = Utils
