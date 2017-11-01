'use strict'

class Cepages extends BaseElement{
  static get is(){return 'vni-cepages'}
  static get properties(){
    return {
      cepages: {
        type: Array,
        notify: true
      },
      readonly: {type: Boolean, value: true}
    }
  }

  // select a cepage
  select(e){
    if (this.readonly)
      return

    var previousSelect = e.currentTarget.parentElement.querySelector('.selected')
    if (previousSelect)
      previousSelect.classList.remove('selected')

    e.currentTarget.classList.add('selected')
  }

  // remove existing cepage
  remove(e){
    this.splice('cepages', e.model.index, 1)
    var node = e.currentTarget.parentElement
    setTimeout(() => node.classList.remove('selected'), 1)
  }

  // add cepage to list
  addCepage(e){
    var value = this.$.newCepage.value

    // check value is not empty & not already in list
    if (value && this.cepages.map(x => x.toLowerCase()).indexOf(value.toLowerCase()) === -1){
      this.push('cepages', this.$.newCepage.value)
      this.$.newCepage.value = ''
    }
    this.$.newCepage.focus()
  }
}

window.customElements.define(Cepages.is, Cepages)
