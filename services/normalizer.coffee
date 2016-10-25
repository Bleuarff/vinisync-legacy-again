Undiacritics = require '../utils/undiacritics.js'

# Normalize bottle properties, to ensure consistency
# Normalization should be done at the controller level, and services assume correct parameters.
class Normalizer

  # stop words to not capitalize, except at the beginning of string
  @stopWords = 'a|à|c|d|j|l|m|n|s|t|y|au|ça|ce|ces|ci|des|du|dos|en|et|hui|ici|la|le|les|là|ma|mes|mon|ni|nous|or|ou|où|par|pas|peu|pour|que|quel|quelle|quelles|quels|qui|sa|sans|ses|si|sien|son|sont|sous|sur|ta|tel|tels|tes|ton|tous|tout|trop|très|tu|votre|vous|vu'.split '|'
  @undiacritics = new Undiacritics()

  # list string or patterns to replace, with substitutions
  @patterns = [
    ['Chateau', 'Château'],
    [/\bSt(e?)\b/g, 'Saint$1'], # expand st, ste into saint, sainte
    [/\b(Sainte?)\s+\b/g, '$1-'] # hyphenate Saint(e) when followed by a word
  ]

  @normalize: (bottle) ->
    for key in Object.keys bottle
      if typeof bottle[key] == 'string'
        value = bottle[key]
        continue if value == null

        value = Normalizer._toTitleCase value
        value = Normalizer._replacePatterns value
        bottle[key] = value
      else if key =='cepages'
        bottle.cepages = bottle.cepages.map (x) -> x.toLowerCase()

    if bottle.name == null || bottle.name == ''
      delete bottle.name

    bottle.cepages = bottle.cepages || []

    return bottle

  # get standard, lowercase, non-accented string, with non-alphanumeric chars converted to space
  @getStandardForm: (input) ->
    value = input.toLowerCase()
    value = Normalizer.undiacritics.removeAll value
    value = value.replace /[^a-z0-9-]/gi, ' '
    return value


  # Applies each pattern on input and replaces it with corresponding substitution
  @_replacePatterns: (input) ->
    for item in Normalizer.patterns
      input = input.replace item[0], item[1]
    return input


  # Converts input to title case, except stop words not at the beginning
  @_toTitleCase: (input) ->
    # TODO: handle more accented chars
    rx = /\b[\wàäâéèêëìïîôöòüûù]+\b/gi
    return input.replace rx, (match, offset) ->
      if (Normalizer.stopWords.indexOf(match) > -1 && offset  > 0)
        rep = match
      else
        rep = match[0].toUpperCase() + match.substring(1).toLowerCase()

      return rep

module.exports = exports = Normalizer
