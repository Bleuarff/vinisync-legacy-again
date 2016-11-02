Polymer({

  is: 'vni-home'

  properties: {
  }

  signinSuccess: (details) ->
    console.log 'signin success. Now what?'

    currentUser = gapi.auth2.getAuthInstance().currentUser.get()
    tokenId = currentUser.getAuthResponse().id_token
    userProfileImage = currentUser.getBasicProfile().getImageUrl()
    app.send '/user/signin', {token: tokenId}, 'POST'
    .then (res) =>
      app.user = res.user
      app.csrfToken = res.csrfToken
      @fire 'redirect', {path: '/cave'}
    .catch (err) =>
      # TODO: show error toast
      console.log 'signin err'

})
