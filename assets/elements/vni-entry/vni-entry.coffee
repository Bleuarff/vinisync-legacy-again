Polymer {
  is: 'vni-entry'
  properties:
    requestWip: Number
    currentYear:
      type: Number
      value: (new Date()).getUTCFullYear()
    countries: Array

  listeners:
    show: '_show'

  observers: [
    '_routeChanged(routeData.id)'
  ],

  _routeChanged: (id) ->
    if app.user?
      this.fire 'show', {entryId: id}

  _show: () ->

  ready: () ->
    this.countries = ['Afrique du sud', 'Allemagne', 'Argentine', 'Australie',
    'Chili', 'Espagne', 'Etats-Unis', 'France', 'Italie', 'Nouvelle Zélande',
    'Portugal']

  inputChanged: (value, endpoint, target) ->
    return if this.requestWip
    return if value.length < 4

    # throttles requests
    this.requestWip = setTimeout () =>
      app.send endpoint, {name: value}
      .then (array) =>
        target.items = array
        this.requestWip = 0
      .catch (err) =>
        # no need to notify on such errors
        console.log "Cannot retrieve #{endpoint}"
        this.requestWip = 0
    , 200

  appellationChanged: (e) ->
    @inputChanged e.target.value, '/appellation', @$.appellation

  producerChanged: (e) ->
    @inputChanged e.target.value, '/producer', @$.producer

}
