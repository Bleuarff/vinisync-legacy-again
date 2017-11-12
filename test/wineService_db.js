'use strict'

// debugger
const chai = require('chai'),
      moment = require('moment'),
      asPromised = require('chai-as-promised'),
      db = require('node-db-connector')

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

  describe('updateWine', () => {
    var wine1 = {appellation: 'Beaume de venise', producer: 'oink oink', name: 'Cuvée X'},
        wine2 = {appellation: 'Beaume de venise', producer: 'oink oink', name: 'Cuvée X', year: 2012},
        id
    before('setup', async () => {
      // await sut.createWine(wine1)
      await sut.createWine(wine2)
    })

    it('create', async () => {
      await sut.updateWine({appellation: 'qsdqpfliqmsenf', producer: 'dmlckmvjdf'}, wine1)
      var doc = await db.vni.collection('wines').findOne(wine1)
      assert.exists(doc)
      assert.exists(doc.createDate)
      assert.isUndefined(doc.year)
      id = doc._id
    })

    it('find', async () => {
      var newWine = {...wine1}
      newWine.producer = 'Coop'
      await sut.updateWine(wine1, newWine)
      let doc = await db.vni.collection('wines').findOne(newWine)
      assert.exists(doc)
      assert.equal(doc.producer, 'Coop')
      assert.isUndefined(doc.year)
      assert.equal(doc._id.toString(), id.toString())
    })
  })
})
