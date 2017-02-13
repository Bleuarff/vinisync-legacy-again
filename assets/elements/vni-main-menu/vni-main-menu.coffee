Polymer {
  is: 'vni-main-menu'

  behaviors: [
    Polymer.NeonAnimationRunnerBehavior
  ]

  properties:
    open:
      type: Boolean
      value: false

    # TODO: cannot make it work with more detailed confi (e.g. duration)
    entryAnimation:
      value: 'slide-left-animation'
    exitAnimation:
      value: 'slide-from-left-animation'

  listeners: {
    toggle: '_toggle'
    'neon-animation-finish': '_onNeonAnimationFinish'
  }

  # triggers animation
  _toggle: () ->
    if !this.open
      this.playAnimation 'entry'
      this.querySelector('.menu').selected = -1
    else
      this.playAnimation 'exit'

  _onNeonAnimationFinish: () ->
    this.open = !this.open
    # console.log 'open: ' + this.open
    if this.open
      this.style.transform = 'translateX(-100%)'
    else
      this.style.transform = 'translateX(0)'

  logout: () ->
    this.fire 'signout'

}
