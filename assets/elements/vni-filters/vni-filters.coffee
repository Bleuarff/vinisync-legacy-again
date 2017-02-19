Polymer({
  is: 'vni-filters'
  properties:
    appellations: Array
    producers: Array
    values:
      type: Object
      value:
        appellation: ''
        producer: ''
        color: ''
        year: null
        apogee: null

  # toggle dsplay of a filter input
  toggleFilter: (e) ->
    e.currentTarget.classList.toggle 'open'
    name = e.currentTarget.getAttribute 'name'
    elem = this.querySelector(".filter-box[name='#{name}']")
    elem.classList.toggle 'hidden'

    # on close, reset filter
    if !e.currentTarget.classList.contains('open') && this.values[name]
      this.set "values.#{name}", null
      # combo-box triggers and on-change event, but not the other filter types
      if elem.tagName != 'VAADIN-COMBO-BOX'
        return this.updateFilter()


  ready: () ->
    self = this
    app.send "/api/cave/#{app.user._id}/appellation"
    .then (values) ->
      self.appellations = values
    .catch () ->
      self.appellations = []

    app.send "/api/cave/#{app.user._id}/producer"
    .then (values) ->
      self.producers = values
    .catch () ->
      self.producers = []

    this.querySelectorAll('vaadin-combo-box').forEach (e) ->
      e.$.overlay.$.scroller.style.fontFamily = 'Roboto'

  # fire event to update entry list
  updateFilter: (e) ->
    # clean empty values
    for k, v of this.values
      if v == null || v == ''
        delete this.values[k]

    this.fire 'filterUpdate', this.values


})
