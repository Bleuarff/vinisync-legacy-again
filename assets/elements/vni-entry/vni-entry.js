'use strict'

class Entry extends BaseElement{
  static get is(){return 'vni-entry'}
  static get properties(){
    return {

    }
  }

  ready(){
    super.ready()
    this.addEventListener('show', e => this.show(e))
  }

  show(e){
    console.log('show !')
    if (!window.user){
      console.log('entry: not logged')
      return
    }

    this._getEntry()
  }

  _getEntry(){
    console.log('TODO: get entry')
  }
}

window.customElements.define(Entry.is, Entry)
