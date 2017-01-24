Polymer {
  is: 'vni-cepages'

  properties:
    cepages: Array
    readonly: {type: Boolean, value: false}

  ready: () ->
    app.send '/api/cepage'
    .then (data) =>
      @fullList = data

  select: (e) ->
    e.stopPropagation()
    return if @readonly
    e.currentTarget.parentElement.classList.toggle 'selected'
    e.currentTarget.parentElement.focus()

  unselect: (e) ->
    e.currentTarget.classList.remove 'selected'

  delete: (e) ->
    this.splice 'cepages', e.model.index, 1

  add: () ->
    input = this.querySelector '.input'
    newValue = input.value
    return if newValue == '' || !newValue?

    input.value = null
    item = this.cepages.find (x) -> x.value == newValue
    if item
      this.fire 'error', {text: "Ce vin contient déjà le cépage '#{newValue}'."}
      return

    this.push 'cepages', {value: newValue}
}
