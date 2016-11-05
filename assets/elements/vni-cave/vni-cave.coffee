Polymer({

  is: 'vni-cave'

  properties: {
    bottles: Array
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
    app.send "/cave/#{app.user._id}"
    .then (cave) =>
      @bottles = cave.bottles
    .catch (err) ->
      console.log 'err'
      # TODO: show toast

})
