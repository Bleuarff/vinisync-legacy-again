Polymer {
  is: 'vni-entry'
  properties:
    requestWip: Number
    currentYear:
      type: Number
      value: (new Date()).getUTCFullYear()
    countries: Array
    entry: Object
    cepages : Array

  listeners:
    show: '_show'

  observers: [
    '_routeChanged(routeData.id)'
  ],

  created: () ->
    this.fire 'pageCreated', {name: this.tagName.toLowerCase()}

  _routeChanged: (id) ->
    if app.user?
      this.fire 'show', {entryId: id}

  _show: (e) ->
    if e.detail.entryId?
      # TODO: retrieve entry
      console.log 'retrieve entry ' + e.detail.entryId
    else
      this.entry =
        bottle:
          appellation: null
          producer: null
          name: null
          year: null
          country: 'France'
          apogeeStart: null
          apogeeEnd: null
          cepages: ['grenache', 'syrah', 'mourvèdre']
        count: 1
        offeredBy: null

    this.cepages = this.entry.bottle.cepages.map (x) -> {value: x}

  ready: () ->
    this.countries = ['Afrique du sud', 'Allemagne', 'Argentine', 'Australie',
    'Chili', 'Espagne', 'Etats-Unis', 'France', 'Italie', 'Nouvelle Zélande',
    'Portugal']

  inputChanged: (value, endpoint, target) ->
    return if this.requestWip
    return if value.length != 3

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

  save: () ->
    # TODO: save entry
    console.log 'save entry'

}
