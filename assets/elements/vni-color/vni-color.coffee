Polymer {
  is: 'vni-color'
  properties:
    color:
      type: String
      notify: true

    isRed:
      type: Boolean,
      computed: 'isColor(color, "red")'
    isWhite:
      type: Boolean,
      computed: 'isColor(color, "white")'
    isRose:
      type: Boolean,
      computed: 'isColor(color, "rose")'


  isColor: (value, compare) ->
    return value == compare

  selectColor: (e) ->
    this.color = e.currentTarget.dataset.color
}
