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
  }

  observers: [
    '_routePageChanged(routeData.page)'
  ],

  _routePageChanged: (page) ->
    this.page = page || 'home'


  _pageChanged: (page) ->
    # Load page import on demand. Show 404 page if fails
    resolvedPageUrl = this.resolveUrl('../vni-' + page + '/' + 'vni-' + page + '.html')
    this.importHref(resolvedPageUrl, null, this._showPage404, true)


  _showPage404: () ->
    this.page = 'z404'

})
