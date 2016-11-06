Polymer {
  is: 'vni-entry'
  properties: {
  }
  listeners:
    show: '_show'

  observers: [
    '_routeChanged(routeData.id)'
  ],

  _routeChanged: (id) ->
    if app.user?
      this.fire 'show', {entryId: id}

  _show: () ->
    
}
