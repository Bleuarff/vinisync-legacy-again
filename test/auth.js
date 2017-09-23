'use strict'

const chai = require('chai'),
      chaiHttp = require('chai-http'),
      asPromised = require('chai-as-promised'),
      config = require('../utils/config.js'),
      moment = require('moment')

chai.use(chaiHttp)
chai.use(asPromised)
const expect = chai.expect

describe('auth tests', () => {
  var app

  before('start server', async () => {
    let server = require('../src/server.js')
    app = await server.start(config.dbConnections, 3005)
  })

  after('stop server', async () => {
    await app.close()
  })

  describe('signup', () => {
    let endpoint = '/api/user/signup'
    it('ok', async () => {
      let email = `${moment().toISOString()}@example.com`

      let res = await chai.request(app)
        .put(endpoint)
        .set('Content-Type', 'application/json')
        .send({
          email: email,
          pwd: 'coincoin',
          name: 'pouet'
        })

      expect(res).to.have.status(201)
      expect(res).to.be.json
      expect(res.body.email).to.equal(email.toLowerCase())
    })

    it('email exists', () => {
      let p = chai.request(app)
        .put(endpoint)
        .set('Content-Type', 'application/json')
        .send({email: 'alonzo@bistro.com', pwd: 'coincoin', name: 'coincoin'})

      expect(p).to.be.rejectedWith('Bad Request')
    })

    it('missing params', () => {
      let p = chai.request(app)
        .put(endpoint)
        .set('Content-Type', 'application/json')
        .send({email: 'alonzo@bistro.com'})
      expect(p).to.be.rejectedWith('Bad Request')
    })
  })

  it('signin', async () => {
    let res = await chai.request(app)
      .post('/api/user/signin')
      .set('Content-Type', 'application/json')
      .send({email: 'alonzo@bistro.com', pwd: 'coincoin'})

    expect(res).to.have.status(200)
    expect(res).to.have.cookie('sessid');
  })
})
