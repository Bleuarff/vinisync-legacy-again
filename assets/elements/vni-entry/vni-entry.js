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
      this.$.appellation.focus()
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
    this.$.appellation.focus()
  }

  cancelEdit(){
    this.isEdit = false
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

  // add/remove 1 bottle to the entry count
  async increment(e){
    if (!this.entry._id)
      return

    var step = parseInt(e.currentTarget.dataset.step, 10)
    if (isNaN(step)){
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec: increment invalide'}))
      return
    }

    try{
      let res = await this.send(`/api/entry/${this.entry._id}/increment`, {step: step}, 'POST')
      this.set('entry.count', res.count)
    }
    catch(err){
      console.error(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec modification', bubbles: true, composed: true}))
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

  appellationChanged(e){
    this.getSuggestions(e.currentTarget, 'appellations')
  }

  producerChanged(e){
    this.getSuggestions(e.currentTarget, 'producers')
  }

  // manages dropdown suggestions for appellation & producer fields
  async getSuggestions(field, endpoint){

    var search = field.filter

    // not enough chars: hide suggestions
    if (search.length < 3){
      field.items = null
      return
    }

    // if already got suggestions, filter manually on standard form
    // so as to ignore accented chars
    if (field.items != null){
      let stdForm = normalizer.getStandardForm(search)
      field.filteredItems = field.items.filter(x => x.stdForm.toLowerCase().indexOf(stdForm) > -1)
      return
    }

    if (this.reqwip)
      return

    this.reqwip = true
    var data = []

    try{
      // retrieve suggestions for given endpoint
      data = await this.send(`/api/${endpoint}`, {search: search})
      field.items = data
    }
    catch(err){
      console.error(err)
    }
    finally{
      this.reqwip = false
    }
  }

  selectPhoto(e){
    this.$.uploader.click()
  }

  async upload(e){
    if (!e.currentTarget.files.length)
      return

    var file = e.currentTarget.files[0]
    if (!file.type.startsWith('image/')){
      this.dispatchEvent(new CustomEvent('error', {detail: 'Le fichier n\'est pas une image ', bubbles: true, composed: true}))
      return
    }

    var imageUrl = URL.createObjectURL(file)

    try{
      let res = await this.send(`/api/image/${file.name}`, file, 'PUT')
      console.log('image uploaded: ' + res.filepath)
      this.entry.wine.pictures = [res.filepath]
    }
    catch(err){
      console.log(err)
      this.dispatchEvent(new CustomEvent('error', {detail: 'Echec upload', bubbles: true, composed: true}))
    }
  }

}

window.customElements.define(Entry.is, Entry)
