Polymer {
  is: 'vni-entry'
  properties:
    entryId: String
    edit: Boolean
    requestWip: Number
    currentYear:
      type: Number
      value: (new Date()).getUTCFullYear()
    countries: {
      type: Array
      value: ['Afrique du sud', 'Allemagne', 'Argentine', 'Australie',
        'Chili', 'Espagne', 'Etats-Unis', 'France', 'Italie', 'Nouvelle Zélande',
        'Portugal']
    }
    containings: {
      type: Array
      value: ['37.5cl', '50cl', '75cl', '1.5L', '3l', '4.5l','6l']
    }
    entry: Object
    cepages : Array
    imageUrl: String
    uploadPath:
      type: String
      value: '/uploads/'
      readOnly: true

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
      p = app.send "/api/entry/#{@entryId}"
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
        count: 1
        # offeredBy: null

    p.then (entry) =>
      this.entry = entry
      this.cepages = this.entry.wine.cepages.map (x) -> {value: x}
      if this.entry.wine.pictures? &&this.entry.wine.pictures.length > 0
        this.imageUrl = this.uploadPath + this.entry.wine.pictures[0]
      else
        this.imageUrl = null
    p.catch (err) =>
      this.fire 'error', {text: 'Impossible de retrouver le vin'}

  ready: () ->

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
    overlay = this.querySelector('.overlay')
    overlay.classList.add 'hidden' if overlay?
    menu = this.querySelector('.editMenu')
    menu.classList.add 'hidden' if menu?
    fab = @querySelector('.edit-fab')
    fab.classList.remove 'hidden' if fab?

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
    this.entry.count = this.setCount this.entry.count

    url = "/api/entry"
    if utils.isNullOrEmpty @entryId
      method = 'PUT'
      okTxt = 'créée'
    else
      url += "/#{@entryId}"
      method = 'POST'
      okTxt = 'sauvegardée'

    app.send url, this.entry, method
    .then (newEntry) =>
      @entryId = newEntry._id
      @fire 'success', {text: "Entrée " + okTxt}
      @cancelEdit()
      # updates route for new entry, no effect on edited entry
      @fire 'redirect', {path: '/entry/' + @entryId}
      # TODO: add entry to local value. redirect cave?
    .catch (err) =>
      @fire 'error', {text: "Erreur de sauvegarde."}

  increment: () ->
    app.send "/api/entry/#{@entryId}/increment", {}, 'POST'
    .then () =>
      # @fire 'success', {text: 'Quantité + 1'}
      @set 'entry.count', @entry.count + 1
    .catch (err) =>
      @fire 'error', {text: 'Erreur: quantité ' + @entry.count}

  decrement: () ->
    app.send "/api/entry/#{@entryId}/decrement", {}, 'POST'
    .then () =>
      # @fire 'success', {text: 'Quantité - 1'}
      @set 'entry.count', @entry.count - 1
    .catch (err) =>
      @fire 'error', {text: 'Erreur: quantité ' + @entry.count}


  setYear: (value) ->
    year = parseInt value, 10
    if !isNaN year
      return year
    else return undefined

  setCount: (value) ->
    count = parseInt value, 10
    if !isNaN count
      return count
    else return 1

  # whether the entry has a picture to display
  _hasPicture: (imageUrl) ->
    return imageUrl? && imageUrl != ''

  # whether to show the add picture button
  _showAddPic: (imageUrl, edit) ->
    return edit && !@_hasPicture(imageUrl)

  # open file selector/camera
  selectPhoto: () ->
    # @fire 'debug', 'selectPhoto'
    picker = this.querySelector(".uploader")
    picker.click()

  # reads selected image
  setPhoto: (e) ->
    return if !e.currentTarget.files.length

    file = e.currentTarget.files[0]
    if file.type.indexOf('image/') != 0
      @fire 'error', {text: "Le fichier #{file.name} n'est pas une image"}
      return

    @imageUrl = URL.createObjectURL(file)
    app.send '/api/image/' + file.name, file, 'PUT'
    .then (res) =>
      console.log 'image uploaded: ' + res.filepath
      @entry.wine.pictures = [res.filepath]
    .catch () ->
      console.log 'image failed'
    return

  # show field for property if it exists or in edit mode
  _showProp: (o, propName, edit) ->
    return !utils.isNullOrEmpty(o.base[propName]) || edit

  # same as showProp but for cepage array only.
  # Property is directly referenced since array should not be null but empty
  _showCepages: (cepages, edit) ->
    return cepages.length > 0 || edit

  # same as showProp but for details values - show if any is set, or in edit mode
  _showDetails: (o, edit) ->
    return o.base.sparkling || o.base.sweet || edit

  # show readonly version of field for property if it exists and not in edit mode
  _showReadonlyProp: (property, edit) ->
    return !utils.isNullOrEmpty(property) && !edit

  # show separator between apogee start & end only if both are defined, or in edit mode
  _showApogeeSeparator: (o, edit) ->
    return o.base.apogeeStart? && o.base.apogeeEnd? || edit
}
