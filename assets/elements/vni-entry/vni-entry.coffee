Polymer {
  is: 'vni-entry'
  properties:
    requestWip: Number
    currentYear:
      type: Number
      value: (new Date()).getUTCFullYear()
    countries: Array
    containings: Array
    entry: Object
    cepages : Array
    hasPhoto: {type: Boolean, value: false}
  listeners:
    show: '_show'

  observers: [
    '_routeChanged(routeData.id)'
  ],

  created: () ->
    this.fire 'pageCreated', {name: this.tagName.toLowerCase()}

  _routeChanged: (id) ->
    if app.user?
      # console.log 'route changed & logged: ' + id
      this.fire 'show', {entryId: id}

  _show: (e) ->
    if e.detail.entryId?
      # TODO: retrieve entry
      console.log 'retrieve entry ' + e.detail.entryId
      p = Promise.resolve {
        wine:
          appellation: 'Faugère'
          producer: 'Château la Liquière'
          country: 'France'
          cepages: []
          containing: '75cl'
          sweet: false
          sparkling: false
        count: 13
      }
    else
      p = Promise.resolve
        wine:
          appellation: null
          producer: null
          # name: null
          # year: null
          country: 'France'
          # apogeeStart: null
          # apogeeEnd: null
          cepages: []
          containing: '75cl'
          # color: null
          sweet: false
          sparkling: false
          # image: null
        count: 1
        # offeredBy: null

    p.then (entry) =>
      this.entry = entry
      this.cepages = this.entry.wine.cepages.map (x) -> {value: x}

  ready: () ->
    this.countries = ['Afrique du sud', 'Allemagne', 'Argentine', 'Australie',
    'Chili', 'Espagne', 'Etats-Unis', 'France', 'Italie', 'Nouvelle Zélande',
    'Portugal']

    this.containings = ['37.5cl', '50cl', '75cl', '1.5L', '3l', '4.5l','6l']

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
    # TODO: validation
    this.entry.wine.cepages = this.cepages.map (x) -> return x.value
    this.entry.wine.year = this.setYear this.entry.wine.year
    this.entry.wine.apogeeStart = this.setYear this.entry.wine.apogeeStart
    this.entry.wine.apogeeEnd = this.setYear this.entry.wine.apogeeEnd

    app.send "/cave/#{app.user._id}/entry", this.entry, 'PUT'
    .then (newEntry) =>
      @fire 'error', {text: "Entrée créée"}
      # TODO: add entry to local value. redirect cave ?
    .catch (err) =>
      @fire 'error', {text: "Impossible de rajouter cette entrée"}

  setYear: (value) ->
    year = parseInt value, 10
    if !isNaN year
      return year
    else return undefined

  # open file selector/camera
  selectPhoto: () ->
    # @fire 'debug', 'selectPhoto'
    picker = this.querySelector(".uploader")
    picker.click()

  # reads selected image
  setPhoto: (e) ->
    return if !e.currentTarget.files.length

    fileInfo = e.currentTarget.files[0]
    if fileInfo.type.indexOf('image/') != 0
      @fire 'error', {text: "Le fichier #{fileInfo.name} n'est pas une image"}
      return

    # @fire 'debug', "fileinfo: #{fileInfo.name} / #{fileInfo.size} bytes"
    reader = new FileReader()
    reader.onload = (e) =>
      # @fire 'debug', 'photo loaded'
      content = e.target.result
      @entry.wine.image = content
      @hasPhoto = true

    reader.onerror = (e) =>
      @fire 'error', {"Impossible de lire le fichier #{fileInfo.name}: #{reader.error.name}"}

    reader.readAsDataURL(fileInfo)

}
