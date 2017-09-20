'use strict'

const assert = require('chai').assert
const sut = require('../services/normalizer.js')

describe('Normalizer', () => {
  describe('standard form', () => {
    var testData = [
      ['Château', 'chateau'], ['St Emilion', 'st emilion']
    ]

    testData.forEach(pair => {
      let [input, expected] = pair
      it(expected, () => {
        var output = sut.getStandardForm(input)
        assert.equal(output, expected)
      })
    })
  })
})
