crypto = require 'crypto'
fs = require 'fs'
path = require 'path'
VError = require 'verror'
cuid = require 'cuid'
mkdirp = require 'mkdirp'
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
    sessionReady = session.createOrRetrieve req, res
    sessionReady.catch () ->
      return next()

    length = req.contentLength()
    imageData = new Buffer length
    pos = 0
    dirpath = '' # path to the directory where image is stored
    filename = '' # generated filename
    imagePath = '' # folder + filename, returned to client

    req.on 'data', (chunk) ->
      chunk.copy imageData, pos, 0
      pos += chunk.length

    # use a promise to wait on end upload before processing it
    endPromise = new Promise (resolve, reject) ->
      req.on 'end', () ->
        return resolve()

    # ensures correct content type
    # TODO: check first bytes for magic number for supported image formats
    if !req.contentType().startsWith 'image/'
      res.send 415, 'file is not an image'
      return next()

    # retrieves file extension
    matches = req.params.name.match /\.\w+?$/
    if matches.length == 0
      res.send 400, 'file extension not found'
      return next()

    filename = cuid() +  matches[0] # generate unique filename
    # logger.debug 'extension: ' + filename

    return sessionReady.then () ->
      # ensures user is logged
      if !utils.hasParams req, res, []
        # use status 0 as a convention to not send a response
        throw utils.error 'User not authenticated', 0

      return new Promise (resolve, reject) ->
        # 1 byte as hex string gives 256 possibilities (00-ff), enough to share a few images.
        # if not enough, incrementing this number is backward-compatible.
        crypto.randomBytes 1, (err, buff) ->
          if err
            return reject new VError err, 'Error generating folder name'
          return resolve buff.toString('hex')
    .then (folder) ->
      imagePath = "#{folder}/#{filename}"
      dirpath = path.resolve config.imageDirectory, folder
      ImageController._checkDirectory dirpath
    .then () ->
      return endPromise
    .then () ->
      fullpath = path.resolve dirpath, filename
      fs.writeFile fullpath, imageData, (err) ->
        if err
          logger.error new VError err, 'save file failure'
          res.send 500
        else
          res.send 201, {filepath: imagePath}
        return next()
    .catch (err) ->
      logger.error new VError err, 'save file failure'
      if err.status
        res.send err.status || 500, 'Error saving file'
      return next()

  # promisify call to mkdirp
  @_checkDirectory: (dirpath) ->
    return new Promise (resolve, reject) ->
      mkdirp dirpath, (err) ->
        if err
          return reject err
        return resolve(dirpath)


ImageController.init()
module.exports = exports = ImageController
