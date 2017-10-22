'use strict'

class Cave extends BaseElement{
  static get is(){return 'vni-cave'}
  static get properties(){
    return {
      entries: {
        type: Array
      },
      count: {type: Number},
      offset: Number,
      pageSize: {Number, value: 5}
    }
  }

  ready(){
    super.ready()
    this.addEventListener('show', e => this.show(e))
  }

  show(e){
    console.log('cave: show')
    if (!window.user) // must be signed-in
      return

    this.offset = 0
    this._getData()

    // TODO: get bottle count
  }

  async _getData(){
    try{
      let chunk = await this.send(`/api/cave/${user._id}`, {offset: this.offset, pageSize: 5})
      this.offset += chunk.entries.length
      this.count = chunk.count

      // set entries or concat chunk into existing entries
      if (this.entries == null)
        this.set('entries', chunk.entries)
      else
        this.set('entries', [...this.entries, ...chunk.entries])

      // basic strategy, just fetch if more available
      // TODO: fetch more only if available & scroll event or no scroll (space left at the bottom)
      if (this.offset < this.count)
        await this._getData()
      return
    }
    catch(err){
      console.error(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec', bubbles: true, composed: true}))
    }
  }
}

window.customElements.define(Cave.is, Cave)
