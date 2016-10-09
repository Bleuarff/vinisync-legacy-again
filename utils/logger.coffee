# Logging system
winston = require 'winston'
require('winston-redis').Redis
fs = require 'fs'
path = require 'path'
VError = require 'verror'

config = require './config.js'

class Logger
  constructor: (@system) ->
    targets = []
    # if no log target registered, log to stdout
    if config.log == null || typeof config.log =='undefined' || config.log.targets == null || typeof config.log.targets =='undefined'
      targets.push new (winston.transports.Console)
    else
      # create a transport for each target defined in config
      for e in config.log.targets
        switch e.type
          when 'stdout'
            transport = new (winston.transports.Console)
              colorize: true
              #timestamp: true
          when 'file'
            if fs.existsSync path.dirname(e.path)
              transport = new (winston.transports.File)
                filename: e.path
            else
              console.log 'directory \'%s\' doesnt\'t exist', path.dirname e.path

          when 'redis'
            transport = new (winston.transports.Redis)
              host: e.host
              port: e.port
              container: e.key

        targets.push transport
        # suppress exceptions when there's an error with the transport
        transport.on 'error', (err) ->
          return

    @winston = new (winston.Logger)
      level: config.log.level
      transports: targets

    @_write 'debug', "#{targets.length} log targets registered", {system: @system}

  # internal method
  _write: (level, msg, data) ->
    data = data || {}
    data.system = @system
    @winston.log level, msg, data

  # dedicated methods for each level
  info: (msg, data) ->
    @_write 'info', msg, data

  warn: (msg, data) ->
    @_write 'warn', msg, data

  debug: (msg, data) ->
    @_write 'debug', msg, data

  # Logs an error
  # @err: VError instance or string
  # @data: additional data when err is a string
  error: (err, data) ->
    if err instanceof VError
      stack = err.stack.substr 8
      currentErr = err
      while currentErr? && typeof currentErr.cause == 'function'
        currentErr = currentErr.cause()
        if currentErr? then stack += '\n  ' + currentErr.stack
      @_write 'error', stack
    else
      @_write 'error', err, data


  # helper to instanciate Logger class
  @create = (system) ->
    return new Logger system

module.exports = exports = Logger
