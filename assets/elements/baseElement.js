'use strict'

// Base class for elements that need some common methods
class BaseElement extends Polymer.Element{
  ready(){
    super.ready()
  }

  // send ajax requests using fetch API
  async send(url, payload = {}, verb = 'GET'){
    var opts = {
      method: verb,
      headers: new Headers()
    }

    if (window.user)
      payload.uid = window.user._id

    // process for state-modifying requests (POST, PUT, etc)
    if (['PUT', 'POST', 'DELETE'].indexOf(verb) > -1){
      if (window.user)
        payload.csrfToken = window.user.csrfToken

      opts.body = JSON.stringify(payload)
      opts.headers.set('Content-Type', 'application/json')
    }
    else { // GET, HEAD: add payload as query string
      let qs = Object.entries(payload).map(x => {
        return `${encodeURIComponent(x[0])}=${encodeURIComponent(x[1])}`
      }).join('&')

      if (qs)
        url += '?' + qs
    }

    try{
      let res = await fetch(url, opts),
          response = await res.json()
      if (res.status === 200 || res.status === 201)
        return response

      return Promise.reject({status: res.status, response: response})
    }
    catch(err){
      console.error(err.message)
      return promise.reject(err.message)
    }
  }
}
