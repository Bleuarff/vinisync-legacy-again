fs = require 'fs'
path = require 'path'
VError = require 'verror'
config = require '../utils/config.js'
session = require '../utils/session.js'
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
    # manually retrieve session
    p = session.createOrRetrieve req, res
    p.catch () ->
      return next()

    p.then () ->
      # ensures user is logged
      if !utils.hasParams req, res, []
        return next(false)

      # ensures correct content type
      if !req.contentType().startsWith 'image/'
        res.send 415
        return next(false)

      length = req.contentLength()
      imageData = new Buffer length
      pos = 0

      try
        req.on 'data', (chunk) ->
          chunk.copy imageData, pos, 0
          pos += chunk.length

        # save file
        req.on 'end', () ->
          # logger.debug 'End, got ' + fileName
          fullpath = path.resolve config.imageDirectory, req.params.name
          # logger.debug 'image saved at ' + fullpath
          fs.writeFile fullpath, imageData, (err) ->
            if err
              logger.error new VError err, 'save file failure'
              res.send 500
            else
              res.send 201
            return next()
      catch err
        logger.error new VError err, 'Upload failure'
        res.send 500, 'upload failure'


ImageController.init()
module.exports = exports = ImageController
