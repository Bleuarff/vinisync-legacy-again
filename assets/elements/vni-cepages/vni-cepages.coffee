Polymer {
  is: 'vni-cepages'

  properties:
    cepages: {type: Array }
    fullList: {type: Array}

  # listeners: {}
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

  showInput: () ->
    input = this.$.input
    input.classList.toggle 'hidden'
    input.value = null
    input.querySelector('input').focus()
    input.close()

  add: (e) ->
    newValue = e.currentTarget.value
    return if newValue == '' || !newValue?

    item = this.cepages.find (x) -> x.value == newValue
    return if item

    this.push 'cepages', {value: newValue}
    e.currentTarget.classList.add 'hidden'
    # e.currentTarget.value = null
}
