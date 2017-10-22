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
      pageSize: {Number, value: 5},
      bottleCount: Number
    }
  }

  ready(){
    super.ready()
    this.addEventListener('show', e => this.show(e))
  }

  async show(e){
    console.log('cave: show')
    if (!window.user) // must be signed-in
      return

    this.offset = 0
    this.entries = null
    this._getData()

    try{
      let res = await this.send(`/api/cave/${user._id}/count`)
      this.bottleCount = res.count
    }
    catch(err){
      console.error(err)
    }
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
        this._getData()
      return
    }
    catch(err){
      console.error(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec', bubbles: true, composed: true}))
    }
  }

  addEntry(e){
    this.dispatchEvent(new CustomEvent('redirect', {detail: '/entry', bubbles: true, composed: true}))
  }
}

window.customElements.define(Cave.is, Cave)
