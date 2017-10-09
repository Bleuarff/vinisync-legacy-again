'use strict'

class App extends Polymer.Element {
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
    console.log('hello app')
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
}

window.customElements.define(App.is, App)
