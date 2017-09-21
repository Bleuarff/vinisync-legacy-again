'use strict'

const assert = require('chai').assert
const sut = require('../services/normalizer.js')

describe('Normalizer', () => {
  describe('standard form', () => {
    var testData = [
      ['Château', 'chateau'], ['St Emilion', 'st emilion'], ['PêraY', 'peray']
    ]

    testData.forEach(([input, expected]) => {
      it(expected, () => {
        var output = sut.getStandardForm(input)
        assert.equal(output, expected)
      })
    })
  })

  describe('replace patterns', () => {
    var testData = [
      ['Chateau St Ange', 'Château Saint-Ange'],
      ['Saint Emilion', 'Saint-Emilion'],
      ['Ste Joseph', 'Sainte-Joseph']
    ]

    testData.forEach(([input, expected]) => {
      it(expected, () => {
        var output = sut._replacePatterns(input)
        assert.equal(output, expected)
      })
    })
  })

  describe('title case', () => {
    var testData = [
      ['chateau', 'Chateau'],
      ['la pêche aux moules', 'La Pêche aux Moules'],
      ['aujourd\'hui en france', 'Aujourd\'hui en France'],
      ['les pierres sèches de simon la pallu', 'Les Pierres Sèches de Simon la Pallu']
    ]

    testData.forEach(([input, expected]) => {
      it(expected, () => {
        var output = sut._toTitleCase(input)
        assert.equal(output, expected)
      })
    })
  })
})
