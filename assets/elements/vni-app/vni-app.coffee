Polymer({

  is: 'vni-app'

  properties: {
    name: {
      type: String
      value: 'Vinisync'
    }
    page: {
      type: String,
      # reflectToAttribute: true,
      observer: '_pageChanged'
    }
    signedIn: {
      type: Boolean
      value: false
    }
  }

  listeners:
    redirect: '_redirect'
    signout: 'signout'
    error: '_error'
    success: '_success'
    debug: '_debug'

  observers: [
    '_routePageChanged(routeData.page)'
  ]

  created: () ->
    self = this

    # resolves when the tag for the current page is created
    @pageLoadPromise = new Promise (resolve, reject) ->
      this.addEventListener 'pageCreated', (e) ->
        tagPage = e.detail.name.split('-')[1]
        if self.page == tagPage
          resolve()

  ready: () ->
    # register service worker
    # if navigator.serviceWorker
    #   window.addEventListener 'load', () ->
    #     setTimeout () ->
    #       navigator.serviceWorker.register '/service-worker.js'
    #       .then (registration) ->
    #         console.log 'SW registered with scope ' + registration.scope
    #       .catch (err) ->
    #         console.log 'registration failure: ' + err
    #     , 1000


    # checks whether user is logged
    app.send '/api/init'
    .then (res) =>
      app.user = res.user
      app.csrfToken = res.csrfToken
      @signedIn = true
      if @route.path == '/'
        @fire 'redirect', {path: '/cave'}
      else
        elem = @$.pages.querySelector "[name='#{@page}']"
        if elem
          if elem.fire
            elem.fire 'show'
          else
            @pageLoadPromise.then () ->
              elem.fire 'show'
        else
          @fire 'error', {text: "La page #{@page} est introuvable"}
    .catch (err) =>
      @signedIn = false
      if err.status != 401
        @fire 'error', {text: 'Erreur de connexion'}
        console.log err

  _routePageChanged: (page) ->
    return if page == this.page
    if this.signedIn || !this.page? || page == 'home' || page == ''
      this.page = page || 'home'
    else
      this.from = page # store page initially requested, for redirection
      this.page = 'z401'

  _pageChanged: (page) ->
    # Load page import on demand. Show 404 page if fails
    resolvedPageUrl = this.resolveUrl('../vni-' + page + '/' + 'vni-' + page + '.html')
    this.importHref(resolvedPageUrl, null, this._showPage404, true)

  _showPage404: () ->
    this.page = 'z404'

  _redirect: (e) ->
    if e.detail && e.detail.path
      this.set 'route.path', e.detail.path
      this.set 'route.__queryParams', {} # redirect removes query parameters

  # show error toast
  _error: (e) ->
    toast = this.$.errorToast
    toast.show e.detail.text

  _success: (e) ->
    toast = this.$.successToast
    toast.show e.detail.text

  hideError: () ->
    this.$.errorToast.hide()

  signout: () ->
    @$['google-signin'].signOut()
    app.send '/api/user/signout', {}, 'POST'
    app.user = null
    app.csrfToken = null
    @fire 'redirect', {path: '/home'}

  # display message in log section
  _debug: (e) ->
    nd = document.createElement 'div'
    nd.innerHTML = e.detail
    this.$.debug.appendChild nd

  toggleMenu: (e) ->
    this.querySelector('.drawer').fire 'toggle'
    this.querySelector('.overlay').classList.toggle 'hidden'

  hidden: (value) ->
    if value then return ''
    return 'hidden'

  hideMenu: (e) ->
    this.querySelector('.drawer').fire 'toggle'
    e.currentTarget.classList.add 'hidden'
})

###
# App object
###
class App

  user: null # base user info (without entries)
  csrfToken: null

  isLogged: () ->
    return app.user? && app.user._id?

  # Sends an ajax request
  send: (url, payload = {}, verb = 'GET') ->
    client = new XMLHttpRequest()
    uri = url

    isBlob = payload instanceof Blob

    if app.isLogged() && !payload.uid? && !url.startsWith('/api/user/') && !url.startsWith('/api/cave/')
      if !isBlob
        payload.uid = app.user._id
      else
        uri += '?uid=' + app.user._id

    if verb == 'GET' || verb == 'HEAD'
      args = []
      for key in Object.keys payload
        args.push encodeURIComponent(key) + '=' + encodeURIComponent payload[key]

      if args.length > 0
        uri += '?' + args.join '&'
    else if this.csrfToken? & !isBlob
      payload.csrfToken = this.csrfToken

    return new Promise (resolve, reject) ->
      client.open verb, uri

      if !isBlob
        client.setRequestHeader 'Content-Type', 'application/json'
        client.setRequestHeader 'Charset', 'utf-8'

        if verb == 'GET' || verb == 'HEAD'
          client.send()
        else
          client.send JSON.stringify payload

      # send blob
      else
        client.send payload

      client.onload = () ->
        if this.status >= 200 && this.status < 300
          if this.status != 204 && this.response != ''
            resolve JSON.parse this.response
          else
            resolve {}
        else
          reject this

      client.onerror = () ->
        reject this

window.app = new App()

class Utils
  isNullOrEmpty: (value) ->
    return !value? || value == ''

window.utils = new Utils()
