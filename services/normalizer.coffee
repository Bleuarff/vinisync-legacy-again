# appellation
# chateau -> château
# st -> Saint
# Saint qqch -> Saint-
# capitaliser / pascal case sauf stopwords

# Normalize bottle properties, to ensure consistency
class Normalizer

  @stopWords = 'au|ça|ce|ces|ci|des|du|dos|en|et|ici|la|le|les|là|ma|mes|mon|ni|nous|or|ou|où|par|pas|peu|pour|que|quel|quelle|quelles|quels|qui|sa|sans|ses|si|sien|son|sont|sous|sur|ta|tel|tels|tes|ton|tous|tout|trop|très|tu|votre|vous|vu'.split '|'


  @normalize: (bottle) ->
    for key in Object.keys bottle
      continue if typeof bottle[key] != 'string'
      res = Normalizer.toTitleCase bottle[key]
      # res = Normalizer.correctWords res
      bottle[key] = res

    return bottle


  # @correctWords: (input) ->
  #   list = [['Chateau', 'Château'], [/st ?/g, ]]
  #   for item in list
  #     return input.replace


  # Converts input to title case, except stop words not at the beginning
  @toTitleCase: (input) ->
    rx = /\b\w+\b/g
    return input.replace rx, (match, offset) ->
      if (Normalizer.stopWords.indexOf(match) > -1 && offset  > 0)
        rep = match
      else
        rep = match[0].toUpperCase() + match.substring(1).toLowerCase()

      return rep

module.exports = exports = Normalizer
