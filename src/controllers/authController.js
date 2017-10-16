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
    if (!utils.hasParams(res, req.params, ['email', 'pwd', 'name']))
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
        res.send(400, 'email déjà utilisé.')
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
      await AuthController._authenticate(req, user)

      res.send(201, {user: user, csrfToken: req.session.data.csrfToken})
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
    if (!utils.hasParams(res, req.params, ['email', 'pwd'])){
      return next()
    }

    var email = req.params.email.toLowerCase()

    try{
      var user = await db.vni.collection('users').findOne({email: email}, {email: 1, name: 1, pwd: 1})
      if (!user)
        throw utils.error('email ou mot de passe incorrect.', 400)

      // compare hash and provided password
      let cmpOk = await bcrypt.compare(req.params.pwd, user.pwd)
      if (!cmpOk)
        throw utils.error('email ou mot de passe incorrect.', 400)

      await AuthController._authenticate(req, user)

      delete user.pwd
      res.send(200, {user: user, csrfToken: req.session.data.csrfToken})
      return next()
    }
    catch(err){
      if (!err.status)
        logger.error(new VError(err, 'Signin error'))

      res.send(err.status || 500, err.status ? err.message : 'Erreur d\'authentication.')
      return next(false)
    }
  }

  static async init(req, res, next){
    // if auth info in session, consider signed in
    // but generate new csrf token, just to be safe
    if (req.session.data.uid && req.session.data.csrfToken){
      req.session.data.csrfToken = await utils.generateUniqueToken()
      req.session.update()
      try{
        let user = await db.vni.collection('users').findOne({_id: ObjectId(req.session.data.uid)}, {
          name: 1, email: 1
        })
        if (!user)
          res.send(401, 'not in db: ' + req.session.data.uid)
        else
          res.send(200, {user: user, csrfToken: req.session.data.csrfToken})
        return next()
      }
      catch(err){
        res.send(401, err)
        return next()
      }
    }
    else{
      res.send(401, 'no data in session')
      return next()
    }
  }

  // kill session & delete cookie
  static signout(req, res, next){
    cookies.delete(res, 'sessid')
    req.session.destroy()
    res.send(200, 'session destroyed')
  }

  // some auth checks:
  // if no uid param, path must be public
  // if uid, must be present in session
  static isLogged(req, res, next){
    const uid = req.params.uid

    if (!uid && AuthController.isPublic(req.getPath())){
      // logger.debug('no uid, public url')
      return next()
    }

    if (uid === req.session.data.uid){
      // logger.debug('uid not equal session')
      return next()
    }

    res.send(401)
    return next(false)
  }

  // whether a given path is defined in list of public paths
  static isPublic(path){
    var isPublicPath = AuthController.publicUrls.some(pattern => {
      if (pattern instanceof RegExp)
        return pattern.test(path)
      else if (typeof pattern === 'string')
        return pattern === path
      else
        return false
    })

    return isPublicPath
  }
}


module.exports =exports = AuthController
