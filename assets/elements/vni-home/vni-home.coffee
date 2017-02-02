Polymer({

  is: 'vni-home'

  properties: {
  }

  observers: [
    '_fromChanged(route.__queryParams)'
  ]

  listeners:
    show: 'show'

  show: () ->
    # if 'from' property is set, redirect to said page. Triggerw show because redirect
    # will display the page without running show if page was already loaded (it sees no route change).
    # Triggering show forces content refresh
    if this.from?
      page = this.from # save value before redirect removes query params
      this.fire 'redirect', {path: "/#{this.from}"}
      elem = document.querySelector("[name='#{page}']")
      elem.fire 'show' if elem.fire?

  signout: () ->
    @fire 'signout'

  #  when page is requested with query params, stores the from parameter
  _fromChanged: (params) ->
    @from = params.from
})
