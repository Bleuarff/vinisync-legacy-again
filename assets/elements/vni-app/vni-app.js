'use strict'

class App extends BaseElement {
  static get is(){return 'vni-app'}
  static get properties(){
    return {
      page: {
        type: String,
        observer: '_pageChanged'
      }
    }
  }

  static get observers(){
    return [
      '_routePageChanged(routeData.page)'
    ]
  }

  ready(){
    super.ready()
    this.addEventListener('error', e => this.showError(e))
    this.addEventListener('success', e => this.showSuccess(e))
    this.addEventListener('redirect', e => this.redirect(e))
    this.addEventListener('close-menu', e => this.$.drawer.close())

    this.init()
  }

  async init(){
    try{
      let res = await this.send('/api/user/init')
      this.dispatchEvent(new CustomEvent('signin', {detail: window.user, bubbles: true, composed: true}))
      window.user = res.user
      window.user.csrfToken = res.csrfToken

      if (this.page === 'home' || this.page === 'signin')
        this.set('route.path', '/cave')
      else{
        // TODO: wait for current component to load and then trigger its show
        console.log('wait & go')
      }
    }
    catch(err){
      console.log('not logged')
    }
  }

  _routePageChanged(page){
    if (page === this.page || typeof page === 'undefined')
      return

    this.page = page || 'home'
  }

  _pageChanged(page){
    var resolvedPageUrl = this.resolveUrl(`../vni-${page}/vni-${page}.html`)
    Polymer.importHref(resolvedPageUrl, (e) => {
      this.root.querySelector(`[name=${page}]`).dispatchEvent(new CustomEvent('show'))
    }, () => {
      this.page = 'z404'
    }, true)
  }

  showError(e){
    this.notif = e.detail
    this.$.errToast.open()
  }

  showSuccess(e){
    this.notif = e.detail
    this.$.okToast.open()
  }

  closeToast(){
    this.$.errToast.close()
  }

  redirect(e){
    this.set('route.path', e.detail)
  }
}

window.customElements.define(App.is, App)
