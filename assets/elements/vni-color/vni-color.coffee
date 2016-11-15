Polymer {
  is: 'vni-color'
  properties:
    # tags:
    #   type: Array
    #   observer: '_tagsChanged'
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
  # _tagsChanged: (value) ->
  #   # console.log 'tags changed'
  #   if !value? || !value.length
  #     this.color = null
  #     return
  #
  #   # set color
  #   if value.indexOf('red') > -1
  #     this.color = 'red'
  #   else if value.indexOf('white') > -1
  #     this.color = 'white'
  #   else if value.indexOf('rose') > -1
  #     this.color = 'rose'
  #
  #   # select color element
  #   if this.color?
  #     elem = this.querySelector(".colors .#{this.color}")
  #     elem.classList.add 'selected'
  #     elem.focus()
  #
  #   # selects the other tag elements
  #   for tag in this.tags
  #     elem = this.querySelector(".tag[data-value='#{tag}']")
  #     if elem
  #       elem.classList.add 'selected'
  #   return

  selectColor: (e) ->
    this.color = e.currentTarget.dataset.color
    # deselect previous element
    # elem = this.querySelector('.color.selected')
    # if elem?
    #   elem.classList.remove 'selected'

    # select element and get new color value
    # e.currentTarget.classList.add 'selected'

    # remove previous color & add new one to tags array
    # prevIndex = this.tags.indexOf this.color
    # if prevIndex > -1
    #   this.splice 'tags', prevIndex, 1, color
    # else
    #   this.push 'tags', color
    # this.color = color

  # selectTag: (e) ->
  #   e.currentTarget.classList.toggle 'selected'
  #   value = e.currentTarget.dataset.value
  #   idx = this.tags.indexOf value
  #
  #   # adds or remove tag from array
  #   if idx > -1
  #     this.splice 'tags', idx, 1
  #   else
  #     this.push 'tags', value
  #   return
}
