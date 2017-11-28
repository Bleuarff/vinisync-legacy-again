'use strict'

const logger = require('swn-logger').create('imageController'),
      fs = require('fs'),
      path = require('path'),
      crypto = require('crypto'),
      VError = require('verror'),
      util = require('util'),
      mkdirp = require('mkdirp'),
      config = require('../../utils/config.js'),
      lstat = util.promisify(fs.lstat),
      writeFile = util.promisify(fs.writeFile),
      randomBytes = util.promisify(crypto.randomBytes),
      pmkdirp = util.promisify(mkdirp)

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

    // check file type
    if (!req.contentType().startsWith('image/')){
      res.send(415, 'Invalid mime type')
      return next(false)
    }

    // check file size
    if (req.body.length > MAX_SIZE){
      res.send(413, `File too large. Max size: ${MAX_SIZE / 1e6}MB`)
      return next(false)
    }

    var fullpath, // absolute path where to save image
        webpath // partial path, the one the client needs to know to retrieve image
    try{
      // generate random directory
      let dirBuf = await randomBytes(1),
          dir = dirBuf.toString('hex'),
          fullDir = path.resolve(config.imageDirectory, dir)

      await pmkdirp(fullDir) // create path

      // generate random filename
      let nameBuf = await randomBytes(4),
          name = nameBuf.toString('hex'),
          extension = path.extname(req.params.name)

      webpath = `${dir}/${name}${extension}`
      fullpath = path.resolve(fullDir,  `${name}${extension}`)
      // logger.debug(`fullpath: ${fullpath}`)
    }
    catch(err){
      logger.error(new VError(err, 'Error setting image path'))
      res.send(500, 'error setting image path')
      return next(false)
    }

    try{
      await writeFile(fullpath, req.body)
      res.send(200, {filepath: webpath})
      return next()
    }
    catch(err){
      logger.error(new VError(err, 'Error saving image'))
      res.send(500, 'error saving image')
      return next(false)
    }
  }
}

ImageController.init()
module.exports = exports = ImageController
