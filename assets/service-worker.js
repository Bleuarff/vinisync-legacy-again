
ASSET_CACHE = 'assets-20170309'
// DATA_CACHE = 'data-20170309'

urlsToCache = [
  '/',
  '/elements/vni-app/vni-app.html',
  '/elements/vni-app/vni-app.js',
  '/elements/vni-home/vni-home.html',
  '/elements/vni-home/vni-home.js',
  '/elements/vni-cave/vni-cave.html',
  '/elements/vni-cave/vni-cave.js',
  '/elements/vni-entry/vni-entry.html',
  '/elements/vni-entry/vni-entry.js',
  '/elements/vni-main-menu/vni-main-menu.html',
  '/elements/vni-main-menu/vni-main-menu.js',
  '/elements/vni-cepages/vni-cepages.html',
  '/elements/vni-cepages/vni-cepages.js',
  '/elements/vni-filters/vni-filters.html',
  '/elements/vni-filters/vni-filters.js',
  '/elements/vni-color/vni-color.html',
  '/elements/vni-color/vni-color.js',
  '/elements/vni-z401/vni-z401.html',
  '/elements/vni-z404/vni-z404.html',
  '/img/vinisync-logo.svg',
  '/styles/shared-styles.html',
  '/bower_components/webcomponentsjs/webcomponents-lite.js',
  '/bower_components/polymer/polymer.html',
  '/bower_components/paper-toolbar/paper-toolbar.html',
  '/bower_components/paper-scroll-header-panel/paper-scroll-header-panel.html',
  '/bower_components/iron-icons/iron-icons.html',
  '/bower_components/paper-icon-button/paper-icon-button.html',
  '/bower_components/google-signin/google-signin-aware.html',
  '/bower_components/iron-pages/iron-pages.html',
  '/bower_components/paper-toast/paper-toast.html',
  '/bower_components/app-route/app-route.html',
  '/bower_components/app-route/app-location.html',
  '/bower_components/polymer/polymer-mini.html',
  '/bower_components/paper-styles/default-theme.html',
  '/bower_components/paper-styles/typography.html',
  '/bower_components/iron-flex-layout/iron-flex-layout.html',
  '/bower_components/iron-resizable-behavior/iron-resizable-behavior.html',
  '/bower_components/iron-icon/iron-icon.html',
  '/bower_components/iron-iconset-svg/iron-iconset-svg.html',
  '/bower_components/paper-behaviors/paper-inky-focus-behavior.html',
  '/bower_components/google-apis/google-js-api.html',
  '/bower_components/iron-selector/iron-selectable.html',
  '/bower_components/iron-a11y-announcer/iron-a11y-announcer.html',
  '/bower_components/iron-overlay-behavior/iron-overlay-behavior.html',
  '/bower_components/iron-location/iron-location.html',
  '/bower_components/iron-location/iron-query-params.html',
  '/bower_components/app-route/app-route-converter-behavior.html',
  '/bower_components/paper-menu/paper-menu.html',
  '/bower_components/paper-item/paper-item.html',
  '/bower_components/neon-animation/neon-animation-runner-behavior.html',
  '/bower_components/neon-animation/animations/slide-left-animation.html',
  '/bower_components/neon-animation/animations/slide-from-left-animation.html',
  '/bower_components/polymer/polymer-micro.html',
  '/bower_components/paper-styles/color.html',
  '/bower_components/font-roboto/roboto.html',
  '/bower_components/iron-meta/iron-meta.html',
  '/bower_components/iron-behaviors/iron-button-state.html',
  '/bower_components/paper-behaviors/paper-ripple-behavior.html',
  '/bower_components/iron-jsonp-library/iron-jsonp-library.html',
  '/bower_components/iron-selector/iron-selection.html',
  '/bower_components/iron-fit-behavior/iron-fit-behavior.html',
  '/bower_components/iron-overlay-behavior/iron-overlay-manager.html',
  '/bower_components/iron-overlay-behavior/iron-focusables-helper.html',
  '/bower_components/iron-menu-behavior/iron-menu-behavior.html',
  '/bower_components/paper-menu/paper-menu-shared-styles.html',
  '/bower_components/paper-item/paper-item-behavior.html',
  '/bower_components/paper-item/paper-item-shared-styles.html',
  '/bower_components/neon-animation/neon-animatable-behavior.html',
  '/bower_components/neon-animation/neon-animation-behavior.html',
  '/bower_components/neon-animation/web-animations.html',
  '/bower_components/iron-a11y-keys-behavior/iron-a11y-keys-behavior.html',
  '/bower_components/iron-behaviors/iron-control-state.html',
  '/bower_components/paper-ripple/paper-ripple.html',
  '/bower_components/iron-overlay-behavior/iron-overlay-backdrop.html',
  '/bower_components/iron-selector/iron-multi-selectable.html',
  '/bower_components/web-animations-js/web-animations-next-lite.min.js',
  '/bower_components/google-signin/google-signin.html',
  '/bower_components/paper-button/paper-button.html',
  '/bower_components/paper-material/paper-material.html',
  '/bower_components/iron-flex-layout/iron-flex-layout-classes.html',
  '/bower_components/google-signin/google-icons.html',
  '/bower_components/google-signin/google-signin.css',
  '/bower_components/paper-behaviors/paper-button-behavior.html',
  '/bower_components/paper-material/paper-material-shared-styles.html',
  '/bower_components/paper-styles/shadow.html',
  '/bower_components/paper-fab/paper-fab.html',
  '/bower_components/paper-spinner/paper-spinner-lite.html',
  '/bower_components/iron-collapse/iron-collapse.html',
  '/bower_components/paper-spinner/paper-spinner-behavior.html',
  '/bower_components/paper-spinner/paper-spinner-styles.html',
  '/bower_components/paper-input/paper-input.html',
  '/bower_components/vaadin-combo-box/vaadin-combo-box.html',
  '/bower_components/iron-form-element-behavior/iron-form-element-behavior.html',
  '/bower_components/iron-input/iron-input.html',
  '/bower_components/paper-input/paper-input-behavior.html',
  '/bower_components/paper-input/paper-input-char-counter.html',
  '/bower_components/paper-input/paper-input-container.html',
  '/bower_components/paper-input/paper-input-error.html',
  '/bower_components/iron-validatable-behavior/iron-validatable-behavior.html',
  '/bower_components/vaadin-combo-box/vaadin-combo-box-behavior.html',
  '/bower_components/vaadin-combo-box/vaadin-combo-box-overlay.html',
  '/bower_components/vaadin-combo-box/vaadin-combo-box-shared-styles.html',
  '/bower_components/vaadin-combo-box/vaadin-combo-box-icons.html',
  '/bower_components/paper-input/paper-input-addon-behavior.html',
  '/bower_components/vaadin-combo-box/vaadin-dropdown-behavior.html',
  '/bower_components/iron-list/iron-list.html',
  '/bower_components/vaadin-combo-box/vaadin-overlay-behavior.html',
  '/bower_components/iron-scroll-target-behavior/iron-scroll-target-behavior.html',
  'https://fonts.googleapis.com/css?family=Roboto:400,300,300italic,400italic,500,500italic,700,700italic',
  'https://fonts.googleapis.com/css?family=Roboto+Mono:400,700',
  'https://fonts.gstatic.com/s/roboto/v15/CWB0XYA8bzo0kSThX0UTuA.woff2',
  'https://fonts.gstatic.com/s/roboto/v15/d-6IYplOFocCacKzxwXSOFtXRa8TVwTICgirnJhmVJw.woff2'
]

// install: set up cache
self.addEventListener('install', (event) => {
  console.log('installing...')
  return event.waitUntil(
    caches.open(ASSET_CACHE)
    .then((cache) => {
      console.log('opened cache ' + ASSET_CACHE)
      return cache.addAll(urlsToCache)
    })
    .then(() => {
      console.log('cache updated')
      // listCacheKeys()
      return Promise.resolve()
    })
    .catch((err) => {
      console.log('Install error: ' + err)
    })
  )
})

function listCacheKeys(){
  caches.open(ASSET_CACHE).then((cache) => {
    return cache.keys()
  })
  .then((keys) => {
    for (k of keys){
      console.log('key: ' + k.url)
    }
  })
}

// activate: remove all other caches except current one
self.addEventListener('activate', (event) => {
  console.log('remove old caches')
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== ASSET_CACHE)
            return caches.delete(cacheName)
        })
      )
    })
    .catch((err) => {
      console.log('Activate error: ' + err)
    })
  )
})

// basic: if in cache, return from cache. else use network, with fallback on cache if timeout
self.addEventListener('fetch', (e) =>{
  e.respondWith(
    caches.open(ASSET_CACHE).then((cache) => {
      return cache.match(e.request)
    })
    .then((matching) => {
      if (matching != null){
        console.log(`${e.request.url} found`)
        return matching
      }

      throw new Error('no match')
    })
    .catch(()=> {
      console.log('no match')
      return fromNetwork(e.request, 400)
    })
    .catch(() => {
      return fromCache(e.request)
    })
  )
})

function fromNetwork(request, timeout){
  return new Promise((resolve, reject) => {
    let timeoutId = setTimeout(reject, timeout)
    fetch(request).then((response) => {
      clearTimeout(timeoutId)
      console.log(`${request.url} retrieved`)
      var rescopy = response.clone()
      resolve(response)
      updateCache(request, rescopy)
    }, reject)
  })
}

function updateCache(request, response) {
  if (request.method === 'GET'){
    caches.open(ASSET_CACHE).then((cache)=>{
      cache.put(request, response)
    })
    .then(() => {
      console.log(`${request.url} cached OK`)
    })
  }
}

function fromCache(request) {
  return caches.open(ASSET_CACHE).then((cache) => {
    return cache.match(request).then((matching) => {
      return matching || Promise.reject('no match')
    })
  })
}
