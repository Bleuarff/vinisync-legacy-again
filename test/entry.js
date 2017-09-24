'use strict'

const chai = require('chai'),
      chaiHttp = require('chai-http'),
      asPromised = require('chai-as-promised'),
      config = require('../utils/config.js'),
      moment = require('moment')

chai.use(chaiHttp)
chai.use(asPromised)
const expect = chai.expect


describe('entry controller', () => {
  var app, agent,uid

  before('start server', async () => {
    let server = require('../src/server.js')
    app = await server.start(config.dbConnections, 3005)

    agent = chai.request.agent(app)
    let res = await agent
      .post('/api/user/signin')
      .set('Content-Type', 'application/json')
      .send({email: 'alonzo@bistro.com', pwd: 'coincoin'})
    expect(res).to.have.cookie('sessid')
    uid = res.body.user._id
  })

  after('stop server', async () => {
    await app.close()
  })

  describe('new entry', () => {
    var now = moment().toISOString(),
        url = '/api/entry?uid=' + uid

    it('pass', async () => {
      let res = await agent.put('/api/entry?uid=' + uid)
      .set('Content-Type', 'application/json')
      .send({
        count: 1,
        wine: {
          appellation: now,
          producer: now,
          year: 2012
        }
      })

      expect(res).to.have.status(201)
      expect(res).to.be.json
      expect(res.body._id).to.match(/[\da-f]+/) // check valid id
    })

    it('add existing entry', async () => {
      let res = await agent.put('/api/entry?uid=' + uid)
        .set('Content-Type', 'application/json')
        .send({
          count: 3,
          wine: {
            appellation: now,
            producer: now,
            year: 2012
          }
        })

      expect(res).to.have.status(200)
      expect(res).to.be.json
      expect(res.body.count).to.be.equal(4)
    })
  })
})
