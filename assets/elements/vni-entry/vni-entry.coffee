Polymer {
  is: 'vni-entry'
  properties:
    entryId: String
    edit: Boolean
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
    if app.user? && id != @entryId
      @entryId = id
      this.fire 'show'

  _show: () ->
    # edit mode disabled when an entry id is provided. Otherwise it's a new entry, set to true
    @edit = utils.isNullOrEmpty @entryId
    if !utils.isNullOrEmpty @entryId
      console.log 'retrieve entry ' + @entryId
      p = app.send "/api/cave/#{app.user._id}/entry/#{@entryId}"
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
    p.catch (err) =>
      this.fire 'error', {text: 'Impossible de retrouver le vin'}

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
    @inputChanged e.target.value, '/api/appellation', @$.appellation

  producerChanged: (e) ->
    @inputChanged e.target.value, '/api/producer', @$.producer

  # hide fab, open display menu & overlay
  openEditMenu: (e) ->
    e.currentTarget.classList.add 'hidden'
    this.querySelector('.editMenu').classList.remove 'hidden'
    this.querySelector('.overlay').classList.remove 'hidden'

  # hide overlay & menu, display fab
  hideMenu: () ->
    this.querySelector('.overlay').classList.add 'hidden'
    this.querySelector('.editMenu').classList.add 'hidden'
    @querySelector('.edit-fab').classList.remove 'hidden'

  setEdit: () ->
    console.log 'go into edit mode'
    @edit = true
    window.scrollTo 0, 0

  cancelEdit: () ->
    @edit = false
    @hideMenu()

  save: () ->
    console.log 'save entry'
    # TODO: validation
    this.entry.wine.cepages = this.cepages.map (x) -> return x.value
    this.entry.wine.year = this.setYear this.entry.wine.year
    this.entry.wine.apogeeStart = this.setYear this.entry.wine.apogeeStart
    this.entry.wine.apogeeEnd = this.setYear this.entry.wine.apogeeEnd

    url = "/api/cave/#{app.user._id}/entry"
    if utils.isNullOrEmpty @entryId
      method = 'PUT'
      okTxt = 'créée'
    else
      url += "/#{@entryId}"
      method = 'POST'
      okTxt = 'sauvegardée'

    app.send url, this.entry, method
    .then (newEntry) =>
      @fire 'success', {text: "Entrée " + okTxt}
      @cancelEdit()
      # TODO: add entry to local value. redirect cave?
    .catch (err) =>
      @fire 'error', {text: "Erreur de sauvegarde."}

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

  # show field for property if it exists or in edit mode
  _showProp: (o, propName, edit) ->
    return !utils.isNullOrEmpty(o.value[propName]) || edit

  # same as showProp but for cepage array only.
  # Property is directly referenced since array should not be null but empty
  _showCepages: (cepages, edit) ->
    return cepages.length > 0 || edit

  # same as showProp but for details values - show if any is set, or in edit mode
  _showDetails: (o, edit) ->
    return o.value.sparkling || o.value.sweet || edit

  # show readonly version of field for property if it exists and not in edit mode
  _showReadonlyProp: (property, edit) ->
    return !utils.isNullOrEmpty(property) && !edit

  # show separator between apogee start & end only if both are defined, or in edit mode
  _showApogeeSeparator: (o, edit) ->
    return o.value.apogeeStart? && o.value.apogeeEnd? || edit
}
