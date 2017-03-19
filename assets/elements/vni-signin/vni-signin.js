'use strict'

Polymer({
  is: 'vni-signin',
  properties: {
    signin: {type: Boolean, value: true},
    selectedTab: {type: Number, value: 0, observer: '_tabChanged'},
    errors: Object,
    hasErrors: {type: Boolean, value: false},
    params: {type: Object, observer: '_paramsChanged'}
  },

  // check input is correct
  validate: function(email, name, pwd1, pwd2, signup){
    this.errors = {}

    // on error, error object property is set to true
    if (utils.isNullOrEmpty(email))
      this.set('errors.noEmail', true)
    else if (!/.+@.+\..+/i.test(email))
      this.set('errors.invalidEmail', true)
    if (utils.isNullOrEmpty(pwd1))
      this.set('errors.noPwd1', true)

    // check pwd length only on signup
    else if (pwd1.length < 8 && signup)
      this.set('errors.shortPwd', true)

    // these checks are only for signup
    if (signup){
      if (utils.isNullOrEmpty(name))
        this.set('errors.noName', true)
      if (pwd1 !== pwd1 || utils.isNullOrEmpty(pwd2))
        this.set('errors.noRepeat', true)
    }

    if (Object.keys(this.errors).length > 0){
      this.hasErrors = true
      return false
    }

    this.hasErrors = false
    return true
  },

  signup: function(){
    var email = this.$['email'].value,
        name = this.$['signup-name'].value,
        pwd1 = this.$['signup-pwd1'].value,
        pwd2 = this.$['signup-pwd2'].value

    this.$['signup-pwd1'].value = this.$['signup-pwd2'].value = ''

    if (!this.validate(email, name, pwd1, pwd2, true))
      return

    let self = this
    app.send('/api/user/signup', {
      email: email,
      name: name,
      pwd: pwd1
    }, 'PUT')
    .then((res)=>{
      self.fire('signin', res)
    })
    .catch((err)=>{
      self._handleServerValidationErrors(err.response)
    })
  },

  signin: function(){
    var email = this.$['email'].value,
        pwd = this.$['signin-pwd'].value

    this.$['signin-pwd'].value = ''

    if (!this.validate(email, null, pwd, null, false))
      return

    let self = this
    app.send('/api/user/signin', {
      email: email,
      pwd: pwd
    }, 'POST')
    .then((res) => {
      self.fire('signin', res)
    })
    .catch((err) => {
      self._handleServerValidationErrors(err.response)
    })
  },

  _handleServerValidationErrors: function(responseTxt){
    try {
      let response = JSON.parse(responseTxt)
      if (response.errors){
        this.set('errors', response.errors)
        this.hasErrors = true
      }
      else {
        this.fire('error', {text: 'Erreur de connexion'})
      }
    }
    catch (e){
      this.fire('error', {text: 'Erreur de connexion'})
    }
  },

  // observer on query string to know if signup or signin
  _paramsChanged: function(params){
    if (params.action != null)
      this.selectedTab = parseInt(params.action, 10)
  },

  // observer on selected tab index, to set focus on email input
  _tabChanged: function(value){
    this.async(() => {
      this.$['email'].focus()
    })
  }
})
