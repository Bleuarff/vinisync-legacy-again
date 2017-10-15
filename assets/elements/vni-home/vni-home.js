'use strict'

class Home extends Polymer.Element{
  static get is(){ return 'vni-home'}
  ready(){
    super.ready()
  }
}

window.customElements.define(Home.is, Home)
