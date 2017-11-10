'use strict'

const assert = require('chai').assert

describe('WineService', () => {
  describe('Validate', () => {
    let srv = require('../services/wineService.js')

    it('pass', () => {
      let input = {
        appellation: 'St Emiliion',
        producer: 'Chateau Ausone',
        year: 1998,
        apogeeStart: 2018,
        apogeeEnd: 2025
      }
      let out = srv.validate(input)
      assert.deepEqual(out, input)
    })

    it('pass minimum', () => {
      let input = {
        appellation: 'St Emiliion',
        producer: 'Chateau Ausone'
      }
      let out = srv.validate(input)
      assert.deepEqual(out, input)
    })

    it('no appellation', () => {
      let data = {
        producer: 'Coincoin'
      }
      assert.throws(srv.validate.bind(null, data), 'missing param appellation')
    })
    it('no producer', () => {
      let data = {
        appellation: 'Coincoin'
      }
      assert.throws(srv.validate.bind(null, data), 'missing param producer')
    })
    it('no data', () => {
      assert.throws(srv.validate.bind(null, null), 'missing param wine')
    })

  })

  describe('CheckYear', () => {
    let srv = require('../services/wineService.js')
    it('missing', () => {
      assert.isUndefined(srv.checkYear())
      assert.isUndefined(srv.checkYear(null))
    })
    it('wrong type', () => {
      assert.throws(srv.checkYear.bind(null, '1998'))
      assert.throws(srv.checkYear.bind(null, {}))
    })
    it('out of range', () => {
      assert.throws(srv.checkYear.bind(null, 2150))
      assert.throws(srv.checkYear.bind(null, 1600))
    })
    it('pass', () => {
      assert.isUndefined(srv.checkYear(2100))
    })
  })

  describe('isEqual false', () => {
    let srv = require('../services/wineService.js')
    var nullInputs = [
      [null, null],
      [null, undefined],
      [undefined, undefined],
      [{}, null],
      [{}, undefined]
    ]

    nullInputs.forEach(([w1, w2]) => {
      it('null', () => {
        var res1 = srv.isEqual(w1, w2)
        var res2 = srv.isEqual(w1, w2)
        assert.isFalse(res1)
        assert.isFalse(res2)
      })
    })

    var falseAppAndProd = [
      [{}, {}],
      [{appellation: 'StJo'}, {}],
      [{appellation: 'StJo'}, {appellation: null}],
      [{appellation: 'StJo'}, {appellation: ''}],
      [{appellation: 'StJo'}, {appellation: 'StEmilion'}],
      [{appellation: 'StJo'}, {appellation: 'StJo'}],
      [{producer: 'Ausone'}, {}],
      [{producer: 'Ausone'}, {producer: null}],
      [{producer: 'Ausone'}, {producer: ''}],
      [{producer: 'Ausone'}, {producer: 'Chidaine'}],
      [{producer: 'Ausone'}, {producer: 'Ausone'}],
    ]

    falseAppAndProd.forEach(([w1, w2]) => {
      it('Invalid appellation / producer', () => {
        var res1 = srv.isEqual(w1, w2),
            res2 = srv.isEqual(w2, w1)
        assert.isFalse(res1)
        assert.isFalse(res2)
      })
    })

    var base = {appellation: 'Jasnières', producer: 'Guigou'}

    var otherFields = [
      [{name: 'coin'}, {name: null}],
      [{name: 'coin'}, {name: undefined}],
      [{name: 'coin'}, {name: ''}],
      [{name: 'coin'}, {name: 'oink'}],
      [{year: 2014}, {year: null}],
      [{year: 2014}, {year: undefined}],
      [{year: 2014}, {year: 2015}],
      [{country: 'coin'}, {country: null}],
      [{country: 'coin'}, {country: undefined}],
      [{country: 'coin'}, {country: ''}],
      [{country: 'coin'}, {country: 'oink'}],
      [{apogeeStart: 2014}, {apogeeStart: null}],
      [{apogeeStart: 2014}, {apogeeStart: undefined}],
      [{apogeeStart: 2014}, {apogeeStart: 2015}],
      [{apogeeEnd: 2014}, {apogeeEnd: null}],
      [{apogeeEnd: 2014}, {apogeeEnd: 2015}],
      [{color: 'red'}, {color: null}],
      [{color: 'red'}, {color: undefined}],
      [{color: 'red'}, {color: ''}],
      [{color: 'red'}, {color: 'white'}],
      [{containing: '75cl'}, {containing: null}],
      [{containing: '75cl'}, {containing: undefined}],
      [{containing: '75cl'}, {containing: ''}],
      [{containing: '75cl'}, {containing: '50cl'}],
    ]

    otherFields.forEach(([p1, p2])=> {
      var w1 = {...base, ...p1},
          w2 = {...base, ...p2}

      it('invalid other fields', () => {
        var res1 = srv.isEqual(w1, w2),
            res2 = srv.isEqual(w2, w1)
        assert.isFalse(res1)
        assert.isFalse(res2)
      })
    })

    var cepages = [
      [{cepages: []}, {cepages: null}],
      [{cepages: []}, {cepages: undefined}],
      [{cepages: []}, {cepages: ['syrah']}],
      [{cepages: ['syrah']}, {cepages: null}],
      [{cepages: ['syrah']}, {cepages: undefined}],
      [{cepages: ['syrah']}, {cepages: ['chenin']}],
      [{cepages: ['syrah', 'cabernet']}, {cepages: ['syrah', 'chenin']}],
      [{cepages: ['syrah', 'cabernet']}, {cepages: ['chenin', 'syrah']}],
      [{cepages: ['syrah', 'cabernet']}, {cepages: ['syrah']}],
    ]

    cepages.forEach(([c1, c2])=>{
      var w1 = {...base, ...c1},
          w2 = {...base, ...c2}

      it('invalid cepages', () => {
        var res1 = srv.isEqual(w1, w2),
            res2 = srv.isEqual(w2, w1)
        assert.isFalse(res1)
        assert.isFalse(res2)
      })
    })

    var details = [
      [{sweet: false}, {sweet: true}],
      [{sparkling: false}, {sparkling: true}],
    ]
    details.forEach(([d1,d2])=>{
      var w1 = {...base, ...d1},
          w2 = {...base, ...d2}
      it('invalid details', () => {
        var res1 = srv.isEqual(w1, w2),
            res2 = srv.isEqual(w2, w1)
        assert.isFalse(res1)
        assert.isFalse(res2)
      })
    })
  })

  describe('isEqual true', () => {
    let srv = require('../services/wineService.js')

    var base = {appellation: 'Champagne', producer: 'Gosset'}

    it('minimum', () => {
      let res = srv.isEqual(base, base)
      assert.isTrue(res)
    })

    var inputs = [
      {name: 'Grande réserve'},
      {name: 'Clappe', year: 2015},
      {name: 'Cuvée spéciale', country: 'France', containing: '75cl', color: 'red'},
      {name: 'Cuvée spéciale', country: 'France', containing: '75cl', apogeeStart: 2017, apogeeEnd: 2032},
    ]

    inputs.forEach(x => {
      let w = {...base, ...x}
      it('main fields', () => {
        var res = srv.isEqual(w, w)
        assert.isTrue(res)
      })
    })

    var cepages = [
      [{cepages: []}, {cepages: []}],
      [{cepages: ['chenin']}, {cepages: ['chenin']}],
      [{cepages: ['chenin', 'syrah']}, {cepages: ['chenin', 'syrah']}],
      [{cepages: ['chenin', 'syrah']}, {cepages: ['syrah', 'chenin']}],
      [{cepages: ['chenin', 'cabernet', 'syrah']}, {cepages: ['cabernet', 'syrah', 'chenin']}],
    ]

    cepages.forEach(([x1, x2]) => {
      let w1 = {...base, ...x1},
          w2 = {...base, ...x2}

      it('valid cepages', () => {
        let res = srv.isEqual(w1, w2),
            res2 = srv.isEqual(w2, w1)
        assert.isTrue(res)
        assert.isTrue(res2)
      })
    })

    var details = [
      [{sweet: true, sparkling: true}, {sweet: true, sparkling: true}],
      [{sweet: true, sparkling: false}, {sweet: true, sparkling: false}],
      [{sweet: false, sparkling: false}, {sweet: null, sparkling: undefined}]
    ]

    details.forEach(([d1, d2]) => {
      let w1 = {...base, ...d1},
          w2 = {...base, ...d2}

      it('details', () => {
        let res = srv.isEqual(w1, w2),
            res2 = srv.isEqual(w2, w1)
        assert.isTrue(res)
        assert.isTrue(res2)
      })
    })
  })
})
