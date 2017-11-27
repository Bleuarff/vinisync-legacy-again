'use strict'

const fs = require('fs'),
      path = require('path'),
      VError = require('verror'),
      util = require('util'),
      lstat = util.promisify(fs.lstat),
      config = require('../../utils/config.js')

const MAX_SIZE = 5 * 1e6 // 5MB max

class ImageController {

  // ensures image directory exists and is valid.
  static async init(){
    if (!config.imageDirectory)
      throw new Error('No image directory defined in config')

    try{
      let stat = await lstat(path.resolve(config.imageDirectory))
      if (!stat.isDirectory())
        throw new Error('Not a directory')
    }
    catch(err){
      throw new VError(err, 'Invalid image directory \'%s\'', config.imageDirectory)
    }
  }

  static async upload(req, res, next){
    res.send(200, {filepath: 'coin pouet'})
    return next()

    // check file type & size
    if (!req.contentType().startsWith('image/')){
      res.send(400, 'Invalid file type')
      return next(false)
    }

    if (req.body.length > MAX_SIZE){
      res.send(413, `File too large. Max size: ${MAX_SIZE / 1e6}MB`)
      return next(false)
    }

    var contentType = req.getContentType()
    if (!contentType.startsWith('image/')){
      res.send(415, 'Invalid mime type')
      return next(false)
    }

    res.send(200, {filepath: 'eat my shorts'})
    return next()
  }
}

ImageController.init()
module.exports = exports = ImageController
