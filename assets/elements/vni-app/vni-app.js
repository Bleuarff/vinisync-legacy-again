'use strict'

class App extends BaseElement {
  static get is(){return 'vni-app'}
  static get properties(){
    return {
      page: {
        type: String,
        value: 'home',
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

    this.init()
  }

  async init(){
    try{
      let res = await this.send('/api/user/init')
      window.user = res.user
      window.user.csrfToken = res.csrfToken

      if (this.page === 'home' || this.page === 'signin')
        this.set('route.path', '/cave')
      else
        console.log('wait & go')
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
    Polymer.importHref(resolvedPageUrl, null, () => {
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
}

window.customElements.define(App.is, App)
