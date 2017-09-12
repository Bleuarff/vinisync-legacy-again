'use strict'

var fs = require('fs'),
    yaml = require('js-yaml'),
    VError = require('verror'),
    file = 'config/config.yml',
    config = null

// Config module: reads the config file and returns a POJO

function readConfig(){
  try {
    let stat = fs.statSync(file)
    if (stat.isFile()){
      let content = fs.readFileSync(file, 'utf8')
      config = yaml.safeLoad(content)
      return config
    }
    else
      throw new VError(`Not a file.`)
  }
  catch(err){
    throw new VError(err, 'Cannot extract config from %s', file)
  }
}
module.exports = exports = config || readConfig()
