'use strict'

class Entry extends BaseElement{
  static get is(){return 'vni-entry'}
  static get properties(){
    return {
      entry: Object,
      isEdit: {type: Boolean, value: false},
      countries: {
        type: Array,
        value: ['Afrique du sud', 'Allemagne', 'Argentine', 'Australie',
          'Chili', 'Espagne', 'Etats-Unis', 'France', 'Italie', 'Nouvelle Zélande',
          'Portugal'],
        readonly: true
      },
      containings: {
        type: Array,
        value: ['37.5cl', '50cl', '75cl', '1.5L', '3l', '4.5l','6l'],
        readonly: true
      },
      currentYear: {
        type: Number,
        value: (new Date()).getUTCFullYear(),
        readonly: true
      }
    }
  }

  ready(){
    super.ready()
    this.addEventListener('show', e => this.show(e))
  }

  show(e){
    // console.log(`show ! path: ${this.route.path}`)
    if (!window.user){
      console.log('entry: not logged')
      return
    }

    if (this.route.path)
      this._getEntry(this.routeData.id)
    else{
      // create new entry. Non-mandatory fields or fields without default value are ommitted
      this.entry = {
        wine: {
          appellation: null,
          producer: null,
          // name: null,
          // year: null,
          country: 'France',
          // apogeeStart: null,
          // apogeeEnd: null,
          cepages: [],
          containing: '75cl',
          color: null,
          sweet: false,
          sparkling: false,
        },
        count: 1
      }
    }
  }

  async _getEntry(id){
    // console.log(`TODO: get entry ${id}`)
    try{
      let entry = await this.send(`/api/entry/${id}`)
      this.entry = entry
    }
    catch(err){
      console.error(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec récup entrée', bubbles: true, composed: true}))
    }
  }

  makeEditable(){
    this.isEdit = true
  }

  save(){
    // TODO save

    this.isEdit = false
  }

  hideProp(value, isEdit){
    return !value && !isEdit
  }

  hideArrayProp(value, isEdit){
    return (!value || value.length === 0) && !isEdit
  }

  hideApogeeSeparator(apogeeStart, apogeeEnd){
    return !apogeeStart || !apogeeEnd
  }

}

window.customElements.define(Entry.is, Entry)
