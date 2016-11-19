Polymer({

  is: 'vni-app'

  properties: {
    name: {
      type: String
      value: 'Vinisync'
    }
    page: {
      type: String,
      reflectToAttribute: true,
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

  _routePageChanged: (page) ->
    this.page = page || 'home'

  _pageChanged: (page) ->
    # Load page import on demand. Show 404 page if fails
    resolvedPageUrl = this.resolveUrl('../vni-' + page + '/' + 'vni-' + page + '.html')
    this.importHref(resolvedPageUrl, null, this._showPage404, true)


  _showPage404: () ->
    this.page = 'z404'

  _redirect: (e) ->
    if e.detail && e.detail.path
      this.set 'route.path', e.detail.path

  # show error toast
  _error: (e) ->
    toast = this.$.errorToast
    toast.show e.detail.text

  signinSuccess: (evt) ->
    currentUser = gapi.auth2.getAuthInstance().currentUser.get()
    tokenId = currentUser.getAuthResponse().id_token
    userProfileImage = currentUser.getBasicProfile().getImageUrl()
    app.send '/user/signin', {token: tokenId}, 'POST'
    .then (res) =>
      app.user = res.user
      app.csrfToken = res.csrfToken
      if @route.path == ''
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
      @fire 'error', {text: 'Erreur de connexion'}
      console.log err


  signout: () ->
    @$['google-signin'].signOut()

  # display message in log section
  _debug: (e) ->
    nd = document.createElement 'div'
    nd.innerHTML = e.detail
    this.$.debug.appendChild nd
})

###
# App object
###
class App

  user: null # base user info (without entries)
  csrfToken: null

  # Sends an ajax request
  send: (url, payload = {}, verb = 'GET') ->
    client = new XMLHttpRequest()
    uri = url

    if verb == 'GET' || verb == 'HEAD'
      args = []
      for key in Object.keys payload
        args.push encodeURIComponent(key) + '=' + encodeURIComponent payload[key]

      if args.length > 0
        uri += '?' + args.join '&'
    else if this.csrfToken?
      payload.csrfToken = this.csrfToken

    return new Promise (resolve, reject) ->
      client.open verb, uri

      client.setRequestHeader 'Content-Type', 'application/json'
      client.setRequestHeader 'Charset', 'utf-8'

      if verb == 'GET' || verb == 'HEAD'
        client.send()
      else
        client.send JSON.stringify payload

      client.onload = () ->
        if this.status >= 200 && this.status < 300
          json = JSON.parse this.response
          resolve json
        else
          reject this

      client.onerror = () ->
        reject this

window.app = new App()
