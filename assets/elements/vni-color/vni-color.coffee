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

    # if selecting the current color, unset completely
    if this.color != e.currentTarget.dataset.color
      this.color = e.currentTarget.dataset.color
    else
      this.color = null
    this.fire 'change', {value: this.color}
}
