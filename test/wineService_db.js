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
    let createDate, input = {
      appellation: moment.utc().toISOString(),
      producer: moment.utc().toISOString(),
      year: 2012,
      cepages: ['syrah', 'sauvignon']
    }

    it('not found -> create', async () => {
      let res = await sut.createWine(input)
      assert.exists(res.value)
      assert.exists(res.value.producer)
      assert.equal(res.value.producer, input.producer)
      assert.exists(res.value._id)
      assert.exists(res.value.createDate)
      createDate = res.value.createDate.toISOString()
    })
    it('wine found, intact', async () => {
      let res = await sut.createWine(input)
      assert.exists(res.value)
      assert.exists(res.value.createDate)
      assert.equal(res.value.createDate.toISOString(), createDate)
    })
  })

  describe('createEntity', () => {
    let createDate, value = moment.utc().toISOString()
    it('not found -> create', async () => {
      let res = await sut.createEntity(value, 'cepages')
      assert.exists(res.value)
      assert.equal(res.value.name, value)
      assert.exists(res.value.createDate)
      createDate = res.value.createDate.toISOString()
    })
    it('found, intact', async () => {
      let res = await sut.createEntity(value, 'cepages')
      assert.exists(res.value)
      assert.equal(res.value.name, value)
      assert.equal(res.value.createDate.toISOString(), createDate)
    })
  })

  describe('propagate', () => {
    it('create all')
    it('all found')
  })
})
