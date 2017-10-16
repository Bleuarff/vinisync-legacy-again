'use strict'

class Signin extends BaseElement{
  static get is(){return 'vni-signin'}
  static get properties(){
    return {
      email: {type: String},
      pwd: {type: String},
      pwd2: {type: String},
      name: {type: String},
      mode: {
        type: String,
        value: 'signin'
      },
      MIN_PWD_LENGTH: {
        type: Number,
        value: 12,
        readOnly: true
      }
    }
  }

  async submit(){
    if (!this.validate())
      return

    var data = {
      email: this.email,
      pwd: this.pwd
    }

    if (this.mode === 'signup')
      data.name = this.name

    var endpoint = `api/user/${this.mode}`,
        method = this.mode === 'signup' ? 'PUT' : 'POST'

    try{
      var res = await this.send(endpoint, data, method)
      this.dispatchEvent(new CustomEvent('success', {detail: 'login/creation OK', bubbles: true, composed: true}))
      window.user = res.user
      window.user.csrfToken = res.csrfToken

      // TODO: redirect to /cave ?
    }
    catch(err){
      this.dispatchEvent(new CustomEvent('error', {detail: err.response, bubbles: true, composed: true}))
    }
  }

  validate(){
    var err
    if (!/.+@.+/.test(this.email))
      err = 'Addresse invalide.'
    else if (!this.pwd)
      err = 'Mot de passe ?'
    else if (this.mode === 'signup'){
      if (!this.name)
        err = 'Nom ?'
      else if (this.pwd.length < this.MIN_PWD_LENGTH)
        err = `le mot de passe doit faire au moins ${this.MIN_PWD_LENGTH} caractères.`
      else if (this.pwd !== this.pwd2)
        err = 'Le mot de passe n\'est pas répété.'
    }

    if (err)
      this.dispatchEvent(new CustomEvent('error', {detail: err, bubbles: true, composed: true}))

    return !err
  }

  isSignin(mode){
    return mode === 'signin'
  }

  buttonLabel(mode){
    return mode === 'signin' ? 'Se connecter' : 'Valider'
  }
}

customElements.define(Signin.is, Signin)
