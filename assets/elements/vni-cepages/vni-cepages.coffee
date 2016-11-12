Polymer {
  is: 'vni-cepages'

  properties:
    cepages: {type: Array }

  # listeners: {}

  select: (e) ->
    e.currentTarget.parentElement.classList.toggle 'selected'
    e.currentTarget.parentElement.focus()
    e.stopPropagation()

  unselect: (e) ->
    e.currentTarget.classList.remove 'selected'

  delete: (e) ->
    this.splice 'cepages', e.model.index, 1

}
