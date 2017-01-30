Polymer({

  is: 'vni-cave'

  properties: {
    bottles: Array
    entryCount: Number
    bottleCount: Number
  }

  listeners:
    show: 'show'

  observers: [
    '_routeChanged(routeData.id)'
  ],


  _routeChanged: (id) ->
    if app.user?
      this.fire 'show'

  show: () ->
    app.send "/api/cave/#{app.user._id}", {offset: 0, count: 20}
    .then (entries) =>
      @bottles = entries.bottles
      @entryCount = entries.entryCount
    .catch (err) ->
      console.log 'err'
      @fire 'error', {text: 'Impossible de récuperer votre cave.'}

    app.send "/api/cave/#{app.user._id}/count"
    .then (res) =>
      @bottleCount = res.count

  addEntry: () ->
    @fire 'redirect', {path: '/entry/'}

})
