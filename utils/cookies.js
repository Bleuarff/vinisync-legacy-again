'use strict'

const moment = require('moment')

class Cookies {

  // Parses the provided string and returns an object with name / value for each cookie
  // @cookie: string to parse. Usually content of the cookie header
  static parse(value){
    var cookies = {}
    if (typeof value === 'string'){
      let elems = value.split(';')
      elems.forEach(cookie => {
        let kv = cookie.split('='),
            name = kv.shift().trim(),
            value = kv.join('=')
        cookies[name] = decodeURIComponent(value.trim())
      })
    }
    return cookies
  }

  // Sets a cookie with name & value
  // @res: response object
  // @name: cookie name
  // @value: cookie value
  // @expires: expiracy date as moment object
  // @httpOnly: whether the cookie is http-only. Defaults to true
  // @secure: whether the cookie is secure (https-only). Defaults to true
  // @sameSite: value to use for SameSite flag. Defaults to Lax
  static set(res, name, value, expires, httpOnly = true, secure = true, sameSite = 'Lax'){
    var cookie = `${name}=${value};`

    if (expires)
      cookie += `expires=${expires.format('ddd, DD MMM YYYY HH:mm:ss')};`
    cookie += ' path=/;'
    if (httpOnly)
      cookie += ' HttpOnly;'
    if (secure)
      cookie += ' Secure;'
    if (sameSite)
      cookie += ` SameSite=${sameSite};`

    var setCookieHeader = res.header('Set-Cookie')
    if (Array.isArray(setCookieHeader))
      setCookieHeader.push(cookie)
    else if (setCookieHeader)
      setCookieHeader = [setCookieHeader, cookie]
    else
      setCookieHeader = cookie

    res.header('Set-Cookie', setCookieHeader)
  }

  // delete cookie
  static delete(res, name){
    Cookies.set(res, name, '', moment('1970-01-01T00:00:00Z'))
  }
}

module.exports = exports = Cookies
