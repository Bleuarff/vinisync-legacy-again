'use strict'

Polymer({
  is: 'vni-signin',
  properties: {
    signin: {type: Boolean, value: true},
    selectedTab: {type: Number, value: 0},
    errors: Object,
    hasErrors: {type: Boolean, value: false}
  },
  signup: function(){
    var email = this.$['signup-email'].value,
        name = this.$['signup-name'].value,
        pwd1 = this.$['signup-pwd1'].value,
        pwd2 = this.$['signup-pwd2'].value

    this.errors = {}

    if (utils.isNullOrEmpty(email))
      this.set('errors.noEmail', true)
    else if (!/.+@.+\..+/i.test(email))
      this.set('errors.invalidEmail', true)
    if (utils.isNullOrEmpty(name))
      this.set('errors.noName', true)
    if (utils.isNullOrEmpty(pwd1))
      this.set('errors.noPwd1', true)
    else if (pwd1.length < 8)
      this.set('errors.shortPwd', true)
    if (pwd1 !== pwd1 || utils.isNullOrEmpty(pwd2))
      this.set('errors.noRepeat', true)

    if (Object.keys(this.errors).length > 0){
      this.hasErrors = true
      return
    }

    this.hasErrors = false
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
      try {
        let response = JSON.parse(err.response);
        if (response.errors){
          self.set('errors', response.errors)
          self.hasErrors = true
        }
      }
      catch (e){}
    })
  },
})
