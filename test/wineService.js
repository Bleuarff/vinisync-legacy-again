'use strict'

const assert = require('chai').assert

describe('WineService', () => {
  describe('Validate', () => {
    let srv = require('../services/wineService.js')

    it('pass', () => {
      let res = srv.validate({
        appellation: 'St Emiliion',
        producer: 'Chateau Ausone',
        year: 1998,
        apogeeStart: 2018,
        apogeeEnd: 2025
      })
      assert.isTrue(res)
    })

    it('pass minimum', () => {
      let res = srv.validate({
        appellation: 'St Emiliion',
        producer: 'Chateau Ausone'
      })
      assert.isTrue(res)
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

})
