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
    if app.user? && this.route.prefix == '/cave'
      this.fire 'show'

  show: () ->
    app.send "/api/cave/#{app.user._id}/bottles", {offset: 0, count: 20}
    .then (entries) =>
      @bottles = entries.bottles
      @entryCount = entries.entryCount
      @bottleCount = entries.bottleCount
    .catch (err) ->
      console.log 'err'
      @fire 'error', {text: 'Impossible de récuperer votre cave.'}

  addEntry: () ->
    @fire 'redirect', {path: '/entry/'}

})
