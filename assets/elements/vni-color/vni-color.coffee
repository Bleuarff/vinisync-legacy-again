Polymer {
  is: 'vni-color'
  properties:
    color:
      type: String
      notify: true
    readonly: {type: Boolean, value: false}

  isColor: (value, compare) ->
    return value == compare

  selectColor: (e) ->
    return if @readonly
    this.color = e.currentTarget.dataset.color
}
