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
        value: ['37.5cl', '50cl', '75cl', '1.5L', '3L', '4.5L','6L', 'autre'],
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

    this.isEdit = false
    if (this.route.path)
      this._getEntry(this.routeData.id)
    else{
      // create new entry. Non-mandatory fields or fields without default value are ommitted
      this.entry = {
        wine: {
          appellation: '',
          producer: '',
          name: null,
          year: null,
          country: 'France',
          apogeeStart: null,
          apogeeEnd: null,
          cepages: [],
          containing: '75cl',
          color: null,
          sweet: false,
          sparkling: false,
        },
        count: 6
      }
      this.isEdit = true
      this.root.querySelector('[label="Appellation"]').focus()
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
    // this.$.menu.classList.add('hidden')
  }

  async save(){
    var endpoint = `/api/entry`,
        method = 'PUT'

    if (this.entry._id){
      endpoint += '/' + this.entry._id
      method = 'POST'
    }

    // cast numeric inputs into number, or delete if empty
    this.entry.count = this.castOrReset(this.entry.count)
    this.entry.wine.year = this.castOrReset(this.entry.wine.year)
    this.entry.wine.apogeeStart = this.castOrReset(this.entry.wine.apogeeStart)
    this.entry.wine.apogeeEnd = this.castOrReset(this.entry.wine.apogeeEnd)

    try{
      this.entry = await this.send(endpoint, this.entry, method)
      this.isEdit = false
      window.scrollTo(0, 0)

      // app routing logic makes this a "false" redirect (page stays the same, so ignored). But location is updated,
      // so a refresh will show the entry instead of the new entry page
      this.dispatchEvent(new CustomEvent('redirect', {detail: `/entry/${this.entry._id}`, bubbles: true, composed: true}))
    }
    catch(err){
      console.error(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec sauvegarde', bubbles: true, composed: true}))
    }
  }

  castOrReset(input){
    var value

    if (input){
      value = parseInt(input, 10)
      return !isNaN(value) ? value : undefined
    }
    return undefined
  }

  toggleMenu(){
    this.$.menuBtn.classList.toggle('hidden')
    setTimeout(() => {this.$.menu.classList.toggle('hidden')}, 5)

  }

  // returns true (field hidden) if all arguments are falsy
  // arguments include isEdit (hide only in readonly, not in edition) and values to check (hide only if falsy)
  hideField(...values){
    return !values.some(x => x)
  }

  hideArrayProp(value, isEdit){
    return (!value || value.length === 0) && !isEdit
  }

  hideContainingInput(value, isEdit){
    return isEdit || !value
  }

  hideApogeeSeparator(apogeeStart, apogeeEnd){
    return !apogeeStart || !apogeeEnd
  }

}

window.customElements.define(Entry.is, Entry)
