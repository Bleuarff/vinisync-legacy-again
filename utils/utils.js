'use strict'

const VError = require('verror')

class Utils {
  // checks the required parameters are in the request. Otherwise returns a 400 status
  // Also performs horizontal privilege escalation check
  // @params: param name or array of param names to check
  // @includeUid (default: true): whether to check for the uid parameter
  static hasParams(req, res, params, includeUid){
    var includeUid = includeUid != null ? includeUid : true,
        pList = includeUid ? ['uid'] : [], // mandatory parameter (in most cases)
        ok = true

    if (typeof params === 'string'){
      pList.push(params)
    }
    else if (Array.isArray(params)){
      pList = pList.concat(params)
    }

    for (let i = 0; i < pList.length; i++){
      if (req.params[pList[i]] == null){
        res.send(400, 'missing parameters')
        ok = false
        break
      }
    }

    // horizontal privilege escalation check
    if (ok && (includeUid || req.params.uid) && req.params.uid !== req.session.data.uid){
      res.send(403, 'forbidden')
      ok = false
    }

    return ok
  }

  static error(message, status, innerErr){
    status = status || 500
    var err
    if (innerErr)
      err = new VError(innerErr, message)
    else
      err = new VError(message)

    err.status = status
    return err
  }
}
module.exports = exports = Utils