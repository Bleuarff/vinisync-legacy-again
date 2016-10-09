
class Cookies

  # Parsees the provided string and returns an object with name / value for each cookie
  # @cookie: string to parse. Usually content of the cookie header
  @parse = (cookie) ->
    cookies = {}
    if cookie
      elems = cookie.split ';'
      for cookie in elems
        kv = cookie.split '='
        k = kv.shift().trim()
        v = kv.join '='
        cookies[k] = decodeURIComponent v.trim()
    return cookies

  # Sets a cookie with name & value
  # @res: response object
  # @name: cookie name
  # @value: cookie value
  # @expires: expiracy date as Date object
  # @httpOnly: whether the cookie is http-only. Defaults to true
  @set = (res, name, value, expires, httpOnly = true) ->
    cookie = "#{name}=#{value};"
    if expires?
      cookie += "expires=#{expires.toUTCString()};"
    cookie += "path=/;"
    if httpOnly
      cookie += ' HttpOnly'
    setCookieHeader = res.header "Set-Cookie"
    # pass array to Set-Cookie header if ptid cookie has already been set for the same response
    if Array.isArray setCookieHeader
      setCookieHeader.push cookie
    else if setCookieHeader
      setCookieHeader = [setCookieHeader, cookie]
    else
      setCookieHeader = cookie

    res.header "Set-Cookie", setCookieHeader

  # Deletes cookie with given name
  @delete = (res, name) ->
    Cookies.set res, name, '', new Date('1970-01-01T00:00:00Z')

module.exports = exports = Cookies
