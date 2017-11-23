'use strict'

const chai = require('chai'),
      chaiHttp = require('chai-http'),
      asPromised = require('chai-as-promised'),
      config = require('../utils/config.js'),
      moment = require('moment'),
      db = require('node-db-connector')

chai.use(chaiHttp)
chai.use(asPromised)
const expect = chai.expect
chai.should()

describe('entities controllers', () => {
  var app, agent,uid, entryId

  before('start server', async () => {
    let server = require('../src/server.js')
    app = await server.start([{connectionString: 'mongodb://localhost:27017/vni-test', name: 'vni'}], 3005)
    agent = chai.request.agent(app)
    let res = await agent
      .put('/api/user/signup')
      .set('Content-Type', 'application/json')
      .send({email: 'bouloubouloutchiktchik@bistro.com', pwd: 'coincoincoin', name: 'boulouboulou'})
    expect(res).to.have.cookie('sessid')
    uid = res.body.user._id
    await db.vni.collection('appellations').insertMany([
      {name: 'Saint-Emilion', stdForm:'saint-emilion'},
      {name: 'Bourgueil', stdForm:'bourgueil'},
      {name: 'Coteaux Varois en Provence', stdForm:'coteaux varois en provence'},
      {name: 'Saint-Joseph', stdForm:'saint-joseph'},
      {name: 'xsfrf', stdForm:'xsfrf'}
    ])
  })

  after('stop server', async () => {
    await app.close()
  })

  describe('appellations', () => {
    it('all', async () => {
      let res = await agent.get(`/api/appellations?uid=${uid}`)
      .set('Content-Type', 'application/json')
      .send()
      expect(res).to.have.status(200)
      expect(res).to.be.json
      expect(res.body).to.be.an('array')
    })

    it('term', async () => {
      let res = await agent.get(`/api/appellations?uid=${uid}&search=xsfrf`)
      .set('Content-Type', 'application/json')
      .send()
      expect(res).to.have.status(200)
      expect(res).to.be.json
      let data = res.body
      expect(data).to.be.an('array')
      expect(data).to.have.lengthOf(1)

    })
  })
})
