'use strict'

// Base class for elements that need some common methods
class BaseElement extends Polymer.Element{
  ready(){
    super.ready()
  }

  // send ajax requests using fetch API
  async send(url, payload = {}, verb = 'GET'){
    var isBlob = payload instanceof Blob,
    opts = {
      method: verb,
      headers: new Headers(),
      credentials: 'same-origin' // to set & use cookies
    }

    if (window.user && !isBlob)
      payload.uid = window.user._id

    // process for state-modifying requests (POST, PUT, etc)
    if (['PUT', 'POST', 'DELETE'].indexOf(verb) > -1){
      if (window.user && !isBlob)
        payload.csrfToken = window.user.csrfToken

      if (isBlob){
        opts.body = payload
        // content-type, content-length set automatically by fetch
        url += `?uid=${encodeURIComponent(window.user._id)}&csrfToken=${window.user.csrfToken}`
      }
      else{
        opts.body = JSON.stringify(payload)
        opts.headers.set('Content-Type', 'application/json')
      }
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
          response = null

      try{
        if (res.headers.has('content-length'))
          response = await res.json()
      }
      catch(err){
        return Promise.reject({status: res.status, response: null})
      }

      if (res.status === 200 || res.status === 201)
        return response

      return Promise.reject({status: res.status, response: response})
    }
    catch(err){
      console.error(err.message)
      return Promise.reject(err.message)
    }
  }
}
