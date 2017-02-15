Polymer({
  is: 'vni-filters'
  properties: {
    appellations: Array
    values:
      type: Object
      value: {
        appellation: ''
        region: ''
        producer: ''
        color: ''
        year: 0
        apogee: 0
      }
  }

  # toggle dspaly of a filter input
  toggleFilter: (e) ->
    name = e.currentTarget.getAttribute 'name'
    elem = this.querySelector(".filter-box[name='#{name}']")
    elem.classList.toggle 'hidden'

  ready: () ->
    self = this
    # TODO: send this request for ~ each keystroke
    app.send '/api/appellation'
    .then (values) ->
      self.appellations = values

  # fire event to update entry list
  updateFilter: (e) ->
    # clean empty values
    for k, v of this.values
      if typeof v == 'string' && v == ''
        delete this.values[k]
      else if typeof v == 'number' && v == 0
        delete this.values[k]

    this.fire 'filterUpdate', this.values
})
