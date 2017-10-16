'use strict'

class Cave extends BaseElement{
  static get is(){return 'vni-cave'}
  static get properties(){
    return {}
  }

  ready(){
    super.ready()
    console.log('cave ready')
  }
}

window.customElements.define(Cave.is, Cave)
