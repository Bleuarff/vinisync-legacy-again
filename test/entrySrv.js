'use strict'

const chai = require('chai'),
      ObjectId = require('bson-objectid'),
      assert = chai.assert


describe('build filters', () => {
  const sut = require('../services/entryService.js')
  var uid = ObjectId().toString()

  it('empty', () => {
    let filters = sut.buildFilters({uid: uid})
    assert.equal(Object.keys(filters).length, 1)
    assert.equal(filters.userId.toString(), uid)
  })

  it('full', () => {
    let filters = sut.buildFilters({
      uid: uid,
      appellation: 'foo',
      producer: 'bar',
      year: 2012,
      color: 'white'
    })
    assert.equal(Object.keys(filters).length, 5)
    assert.isTrue(filters['wine.appellation'] instanceof RegExp)
    assert.isTrue(filters['wine.producer'] instanceof RegExp)
    assert.equal(filters['wine.year'], 2012)
  })

  it('apogee', () => {
    let filters = sut.buildFilters({uid: uid, apogee: 2020})
    assert.equal(Object.keys(filters).length, 2)
    let apogee = filters.$or
    assert.equal(apogee.length, 3)
  })
})
