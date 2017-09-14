'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('authController'),
      db = require('node-db-connector'),
      utils = require('../../utils/utils.js'),
      bcrypt = require('bcrypt'),
      moment = require('moment'),
      uuidv4 = require('uuid/v4'),
      ObjectId = require('bson-objectid')


class AuthController {

  static validate(profile){
    let errs = {}
    if (!profile.email)
      errs.noEmail = true
    else if (!/.+@.+\..+/i.test(profile.email))
      errs.invalidEmail = true
    if (!profile.name)
      errs.noName = true
    if (!profile.pwd)
      errs.noPwd1  = true
    else if (profile.pwd.length < 8)
      errs.shortPwd = true

    return errs
  }

  static async signup(req, res, next){
    if (!utils.hasParams(req, res, ['email', 'pwd', 'name'], false))
      return next(false)

    var profile = req.params,
        validationErrors = AuthController.validate(profile)

    if (Object.keys(validationErrors).length > 0){
      res.send(400, {errors: validationErrors})
      return next(false)
    }

    profile.email = profile.email.toLowerCase()
    try{
      var emailUser = await db.vni.collection('users').findOne({email: profile.email})
      if (emailUser){
        res.send(400, {errors: {usedEmail: true}})
        throw null
      }
      var hash = await bcrypt.hash(profile.pwd, 12),
          id = ObjectId(),
          now = moment.utc().toDate()

      await db.vni.collection('users').insertOne({
        _id: id,
        email: profile.email,
        name: profile.name,
        pwd: hash,
        enabled: true,
        confirmed: false,
        confirmId: uuidv4(),
        createDate: now,
        updateDate: now
      })

      var user = await db.vni.collection('users').findOne({_id: id}, {email: 1, name: 1})

      res.send(201, user)
      return next()
    }
    catch(err){
      if (err){
        if (!err.status)
          logger.error(err)

        res.send(err.status || 500, 'signup error')
      }
      return next(false)
    }
  }
}


module.exports =exports = AuthController
