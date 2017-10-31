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
}

window.customElements.define(Cepages.is, Cepages)
