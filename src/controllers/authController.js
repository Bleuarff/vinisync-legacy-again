'use strict'

const VError = require('verror'),
      logger = require('swn-logger').create('authController'),
      db = require('node-db-connector'),
      bcrypt = require('bcrypt'),
      moment = require('moment'),
      uuidv4 = require('uuid/v4'),
      ObjectId = require('bson-objectid'),
      utils = require('../../utils/utils.js'),
      cookies = require('../../utils/cookies.js')


const BCRYPT_ITERATIONS = 12


class AuthController {

  static _validate(profile){
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

  // updates session with user info, generates new csrf token
  static async _authenticate(req, user){
    req.session.data.uid = user._id.toString()
    req.session.data.email = user.email

    try {
      req.session.data.csrfToken = await utils.generateUniqueToken()
      await req.session.update()
      return
    }
    catch(err){
      throw new VError(err, 'authentication setup error')
    }
  }

  // create user account
  static async signup(req, res, next){
    if (!utils.hasParams(req, res, ['email', 'pwd', 'name'], false))
      return next(false)

    var profile = req.params,
        validationErrors = AuthController._validate(profile)

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
      var hash = await bcrypt.hash(profile.pwd, BCRYPT_ITERATIONS),
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

  // user log in
  static async signin(req, res, next){
    if (!utils.hasParams(req, res, ['email', 'pwd'], false)){
      return next()
    }

    var email = req.params.email.toLowerCase()

    try{
      var user = await db.vni.collection('users').findOne({email: email}, {email: 1, name: 1, pwd: 1})
      if (!user)
        throw utils.error('Signin error', 400)

      // compare hash and provided password
      let cmpOk = await bcrypt.compare(req.params.pwd, user.pwd)
      if (!cmpOk)
        throw utils.error('Signin error', 400)

      await AuthController._authenticate(req, user)

      delete user.pwd
      res.send(200, {user: user, csrfToken: req.session.data.csrfToken})
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Signin error'))

      res.send(err.status ||500, 'Signin error')
      return next(false)
    }
  }

  // kill session & delete cookie
  static signout(req, res, next){
    cookies.delete(res, 'sessid')
    req.session.destroy()
    res.send(200, 'session destroyed')
  }
}


module.exports =exports = AuthController
