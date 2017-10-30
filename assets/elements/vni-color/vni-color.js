'use strict'

class Color extends  BaseElement{
  static get is(){return 'vni-color'}
  static get properties(){
    return {
      color: {type: String, notify: true},
      readonly: {type: Boolean, value: false}
    }
  }

  select(e){
    if (this.readonly)
      return

    if (e.currentTarget.classList.contains('white'))
      this.color = 'white'
    else if (e.currentTarget.classList.contains('red'))
      this.color = 'red'
    else if (e.currentTarget.classList.contains('rose'))
      this.color = 'rose'
  }
}

window.customElements.define(Color.is, Color)
