Undiacritics = require '../utils/undiacritics.js'

# Normalize wine properties, to ensure consistency
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

  @normalize: (wine) ->
    for key in Object.keys wine

      # delete null fields
      if !wine[key]? || wine[key] == ''
        delete wine[key]
        continue

      if typeof wine[key] == 'string'
        if key == 'color'
          wine.color = wine.color.toLowerCase()
          continue

        value = wine[key]
        value = Normalizer._toTitleCase value
        value = Normalizer._replacePatterns value
        wine[key] = value
      else if key =='cepages'
        wine.cepages = wine.cepages.map (x) -> x.toLowerCase()

    wine.cepages = wine.cepages || []

    return wine

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
    rx = /\b[\wàäâéèêëìïîôöòüûùç]+\b/gi
    return input.replace rx, (match, offset) ->
      if (Normalizer.stopWords.indexOf(match) > -1 && offset  > 0)
        rep = match
      else
        rep = match[0].toUpperCase() + match.substring(1).toLowerCase()

      return rep

module.exports = exports = Normalizer
