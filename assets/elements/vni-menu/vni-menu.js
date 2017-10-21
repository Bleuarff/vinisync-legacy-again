'use strict'

class Menu extends BaseElement{
  static get is(){return 'vni-menu'}
  static get properties(){
    return {
      authWording: {type: String, value: 'Connexion'}
    }
  }

  ready(){
    super.ready()
    document.querySelector('vni-app').addEventListener('signin', e => {
      this.authWording = 'Deconnexion'
    })
  }

  async switchAuth(e){
    // if not logged, just let it go and redirect to signin
    if (!window.user)
      return

    e.preventDefault()

    try{
      // signed-in => signout
      await this.send('/api/user/signout')
      delete window.user
      this.authWording = 'Connexion'

       // neded as preventDefault does not close the drawer
      this.dispatchEvent(new CustomEvent('close-menu', {bubble: true, composed: true}))
      this.dispatchEvent(new CustomEvent('redirect', {detail: '/home', bubble: true, composed: true}))
    }
    catch(err){
      console.log(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec déconnexion', bubbles: true, composed: true}))
    }
  }
}

window.customElements.define(Menu.is, Menu)
