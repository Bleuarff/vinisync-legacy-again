self = null
Polymer({

  is: 'vni-cave'

  properties: {
    entries: Array
    entryCount: Number
    filteredCount: {type: Number, value: -1}
    bottleCount: Number # sum of bottles for all entries
    page: {type: String, observer: '_pageChanged'}
    loading: {type: Boolean, readOnly: true, value: false} # wether a query is currently in progress
    filters:
      type: Object
      value: {}
  }

  listeners:
    show: 'show'
    filterUpdate: '_filterUpdate'

  observers: [
    '_routeChanged(routeData.id)'
  ],

  _routeChanged: (id) ->
    if app.user?
      this.fire 'show'

  ready: () ->
    self = this

    # register an observer when grid element is changed
    @_gridObserver = Polymer.dom(@$.grid).observeNodes(@_gridChanged)
    @height = Math.max(document.documentElement.clientHeight, window.innerHeight || 0)


  show: () ->
    @entries = []
    @offset = 0

    @queryPage()
    .catch (err) =>
      console.error err
      @fire 'error', {text: 'Impossible de récuperer votre cave.'}

    app.send "/api/cave/#{app.user._id}/count"
    .then (res) =>
      @bottleCount = res.count

  # adds or removes scroll listener when navigating to or away from the page
  _pageChanged: (page) ->
    if page == 'cave'
      document.querySelector('paper-scroll-header-panel').addEventListener 'content-scroll', @_scroll
    else
      document.querySelector('paper-scroll-header-panel').removeEventListener 'content-scroll', @_scroll

  # actual query to retrieve entries
  queryPage: () ->
    return Promise.resolve() if @loading # blocks new queries if one is in progress
    @_setLoading true

    filters = this._clone this.filters
    filters.offset = @offset
    filters.count = 20
    return app.send "/api/cave/#{app.user._id}", filters
    .then (entries) =>
      # console.log 'got entries'
      @_setLoading false
      @entries = @entries.concat entries.bottles

      # updates counters only if offset is 0. These counters do not change for
      # pagination requests, no need to update them each and every time.
      if @offset == 0
        if Object.keys(this.filters).length == 0
          @entryCount = entries.entryCount
          @filteredCount = -1
        else
          @filteredCount = entries.entryCount
      @offset += entries.bottles.length
      return entries.entryCount
    .catch () =>
      @_setLoading false

  # on scroll, check if we need to query a new chunk of entries.
  _scroll: () ->
    # use setTimeout to debounce scroll events
    return if self.scrollItv
    self.scrollItv = setTimeout () ->
      gridBottom = self.$.grid.getBoundingClientRect().bottom
      if self.offset < self.entryCount && gridBottom < self.height + 500
        # timeout id is reset when query is done to block scroll handling,
        # and prevent new queries until current one is done
        self.queryPage()
        .then () ->
          self.scrollItv = 0
        .catch () ->
          self.scrollItv = 0
      else
        self.scrollItv = 0
    , 250

  # when grid is changed, checks if there's enough space at the bottom of the page
  # or need to make a new request
  _gridChanged: (changes) ->
    return if changes.addedNodes.length <= 3 # template business, not interesting changes
    gridBottom = this.getBoundingClientRect().bottom
    # console.log 'bottom: ' + gridBottom
    if self.offset < self.entryCount && gridBottom < self.height + 500
      self.queryPage()
      .catch (err) ->
        console.log err
        self.fire 'error', {text: 'Erreur de récupération de votre cave'}


  addEntry: () ->
    @fire 'redirect', {path: '/entry/'}

  # toggle filters display
  toggleFilters: () ->
    this.querySelector('#collapse-filters').toggle()

  # filters have been updated, send a new request
  _filterUpdate: (e) ->
    this.filters = e.detail
    console.log e.detail

    this.entries = []
    this.offset = 0
    this.queryPage()
    .catch (err) =>
      console.error err
      @fire 'error', {text: 'Impossible de récuperer votre cave.'}

  # shallow clone
  _clone: (o) ->
    return o if !o?
    res = {}
    for k, v of o
      res[k] = v
    return res

  _noFilterResults: (filteredCount) ->
    return filteredCount == 0

  _hasFilterResults: (filteredCount) ->
    return filteredCount > 0


})
