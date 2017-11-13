'use strict'

const Undiacritics = require('../utils/undiacritics.js')

// stop words to not capitalize, except at the beginning of string
const stopWords = 'a|à|c|d|j|l|m|n|s|t|y|au|aux|ça|ce|ces|ci|de|des|du|dos|en|et|hui|ici|la|le|les|là|ma|mes|mon|ni|nous|or|ou|où|par|pas|peu|pour|que|quel|quelle|quelles|quels|qui|sa|sans|ses|si|sien|son|sont|sous|sur|ta|tel|tels|tes|ton|tous|tout|trop|très|tu|votre|vous|vu'.split('|'),
      undiacritics = new Undiacritics(),
      // list string or patterns to replace, with substitutions
      patterns = [
        ['Chateau', 'Château'],
        [/\bSt(e?)\b/g, 'Saint$1'], // expand st, ste into saint, sainte
        [/\b(Sainte?)\s+\b/g, '$1-'] // hyphenate Saint(e) when followed by a word
      ],
      // split an input by words
      wordsRx = /\b[\wàäâéèêëìïîôöòüûùç]+\b/gi // TODO: handle more accented chars

class Normalizer{

  // fix object's properties
  static normalize(wine){
    var keys = Object.keys(wine)
    keys.forEach(key => {

      if (wine[key] == null || wine[key] === ''){
        delete wine[key]
        return
      }

      if (typeof wine[key] === 'string'){
        if (key === 'color'){
          wine.color = wine.color.toLowerCase()
          return
        }
        if (key === 'containing')
          return

        let value = Normalizer._toTitleCase(wine[key])
        value = Normalizer._replacePatterns(value)
        wine[key] = value
      }
      else if (key === 'cepages'){
        wine.cepages = wine.cepages.map(x => {return x.toLowerCase()})
      }
    })
    wine.cepages = wine.cepages || []
    return wine
  }

  // get standard, lowercase, non-accented string, with non-alphanumeric chars converted to space
  static getStandardForm(input){
    var value = input.toLowerCase()
    value = undiacritics.removeAll(value)
    value = value.replace(/[^a-z0-9-]/gi, ' ') // replace all non-alphanumeric char by a space
    return value
  }

  // # Applies the ccorrect pattern on input and replaces it with corresponding substitution
  static _replacePatterns(input){
    patterns.forEach(([pattern, fixValue]) => {
      input = input.replace(pattern, fixValue)
    })
    return input
  }


  // Converts input to title case, except stop words not at the beginning
  static _toTitleCase(input){
    return input.replace(wordsRx, (match, offset) => {
      var rep
      if (stopWords.indexOf(match) > -1 && offset > 0)
        rep = match
      else
        rep = match[0].toUpperCase() + match.substring(1).toLowerCase()
      return rep
    })
  }
}

module.exports = exports = Normalizer
