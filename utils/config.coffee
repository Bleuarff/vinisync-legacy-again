fs = require 'fs'
yaml = require 'js-yaml'
file = 'config/config.yml'
VError = require 'verror'

# Config module: reads the config file and returns a POJO

config = null

readConfig = () ->
  if fs.existsSync file
    content = fs.readFileSync file, 'utf-8'
    try
      config = yaml.safeLoad content
      return config
    catch ex
      throw new VError ex, 'Cannot parse config'
  else
    throw new VError 'Config file %s does not exist', file

module.exports = exports = config || readConfig()
