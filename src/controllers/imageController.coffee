fs = require 'fs'
path = require 'path'
VError = require 'verror'
config = require '../utils/config.js'
utils = require '../utils/utils.js'
logger = require('../utils/logger.js').create 'picture'

class ImageController

  # ensures image directory is valid.
  @init: () ->
    if utils.isNullOrEmpty config.imageDirectory
      throw new VError 'No image directory defined in config'

    try
      stats = fs.statSync path.resolve config.imageDirectory
    catch err
      throw new VError err, "Image directory '#{config.imageDirectory}' is invalid"

  @upload: (req, res, next) ->
    # if !utils.hasParams req, res, []
    #   return next()

    # TODO:
    # - wait for session to make sure user is logged
    # - define directory in config
    # - check dir exists on module load
    # - save to that directory
    # - catch handler in client
    # - error 413 request entity too large ?

    try
      length = req.contentLength()
      imageData = new Buffer length
      pos = 0

      req.on 'data', (chunk) ->
        chunk.copy imageData, pos, 0
        pos += chunk.length

      # save file
      req.on 'end', () ->
        # logger.debug 'End, got ' + fileName
        filename = ImageController._getFilename req
        fullpath = path.resolve config.imageDirectory, filename
        logger.debug 'write to ' + fullpath
        fs.writeFile fullpath, imageData, (err) ->
          if err
            logger.error new VError err, 'save file failure'
          res.send 204
          return next()
    catch err
      logger.error new VError err, 'Upload failure'
      res.send 500, 'upload failure'


  @_getFilename = (req) ->
    matches = req.contentType().match(/\/(.*)/)
    extension = matches[1]
    return req.params.id + '.' + extension

ImageController.init()
module.exports = exports = ImageController
