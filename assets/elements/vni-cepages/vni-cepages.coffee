Polymer {
  is: 'vni-cepages'

  properties:
    cepages: {type: Array }
    fullList: {type: Array}

  ready: () ->
    app.send '/cepage'
    .then (data) =>
      @fullList = data

  select: (e) ->
    e.currentTarget.parentElement.classList.toggle 'selected'
    e.currentTarget.parentElement.focus()
    e.stopPropagation()

  unselect: (e) ->
    e.currentTarget.classList.remove 'selected'

  delete: (e) ->
    this.splice 'cepages', e.model.index, 1

  add: () ->
    input = this.$.input
    newValue = input.value
    return if newValue == '' || !newValue?

    input.value = null
    item = this.cepages.find (x) -> x.value == newValue
    if item
      this.fire 'error', {text: "Ce vin contient déjà le cépage '#{newValue}'."}
      return

    this.push 'cepages', {value: newValue}
}
