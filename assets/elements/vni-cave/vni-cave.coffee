self = null
Polymer({

  is: 'vni-cave'

  properties: {
    entries: Array
    entryCount: Number
    bottleCount: Number
    page: {type: String, observer: '_pageChanged'}
    # wether a query is currently in progress
    loading: {type: Boolean, readOnly: true, value: false}
  }

  listeners:
    show: 'show'

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
    return app.send "/api/cave/#{app.user._id}", {offset: @offset, count: 20}
    .then (entries) =>
      # console.log 'got entries'
      @_setLoading false
      @entries = @entries.concat entries.bottles
      @entryCount = entries.entryCount
      @offset += entries.bottles.length
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

})
