'use strict'

class Cave extends BaseElement{
  static get is(){return 'vni-cave'}
  static get properties(){
    return {}
  }

  ready(){
    super.ready()
    this.addEventListener('show', e => this.show(e))
  }

  show(e){
    console.log('cave: show')
    if (!window.user) // must be signed-in
      return

    this.getData()
  }

  async getData(){
    try{
      let chunk = await this.send('/api/cave')
    }
    catch(err){
      console.error(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec', bubbles: true, composed: true}))
    }
  }
}

window.customElements.define(Cave.is, Cave)
