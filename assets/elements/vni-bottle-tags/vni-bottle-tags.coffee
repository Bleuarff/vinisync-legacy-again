Polymer {
  is: 'vni-bottle-tags'
  properties:
    color: String

  selectColor: (e) ->

  selectTag: (e) ->
    e.currentTarget.classList.toggle 'selected'
}
