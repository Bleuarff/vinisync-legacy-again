'use strict'

// debugger
const chai = require('chai'),
      moment = require('moment'),
      asPromised = require('chai-as-promised')

chai.use(asPromised)
const assert = chai.assert
const sut = require('../services/wineService.js')

describe('Wine Service DB', () => {
  describe('createWine', () => {
    it('not found -> create', async () => {
      let input = {
        appellation: moment.utc().toISOString(),
        producer: moment.utc().toISOString(),
        year: 2012,
        cepages: ['syrah', 'sauvignon']
      }

      let res = await sut.createWine(input)
      assert.exists(res.value)
      assert.exists(res.value.producer)
      assert.equal(res.value.producer, input.producer)
      // more assertions: look for id, etc
    })

    it('wine found, intact')
    it('')
  })

  describe('createEntity')
  describe('propagate')
})
