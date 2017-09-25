'use strict'

const chai = require('chai'),
      chaiHttp = require('chai-http'),
      asPromised = require('chai-as-promised'),
      config = require('../utils/config.js'),
      moment = require('moment')

chai.use(chaiHttp)
chai.use(asPromised)
const expect = chai.expect
chai.should()

describe('entry controller', () => {
  var app, agent,uid, entryId

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
      entryId = res.body._id
      return expect(entryId).to.match(/[\da-f]+/) // check valid id
    })

    it('add existing entry', async () => {
      let res = await agent.put('/api/entry?uid=' + uid)
        .set('Content-Type', 'application/json')
        .send({
          count: 2,
          wine: {
            appellation: now,
            producer: now,
            year: 2012
          }
        })

      expect(res).to.have.status(200)
      expect(res).to.be.json
      expect(res.body.count).to.be.equal(3)
    })
  })

  describe('increment', () => {
    it('pass', async () => {
      let res = await agent.post(`/api/entry/${entryId}/increment`)
        .query({uid: uid, step: 4})
        .set('Content-Type', 'application/json')
        .send({})

      expect(res).to.have.status(200)
      expect(res).to.be.json
      expect(res.body.count).to.be.equal(7)
    })

    it('decrement', async () => {
      let res = await agent.post(`/api/entry/${entryId}/increment`)
        .query({uid: uid, step: -1})
        .set('Content-Type', 'application/json')
        .send({})

      expect(res).to.have.status(200)
      expect(res).to.be.json
      expect(res.body.count).to.be.equal(6)
    })

    it('decrement below 0', async () => {
      let res = await agent.post(`/api/entry/${entryId}/increment`)
        .query({uid: uid, step: -15})
        .set('Content-Type', 'application/json')
        .send({})

      expect(res).to.have.status(200)
      expect(res).to.be.json
      expect(res.body.count).to.be.equal(0)
    })

    it('invalid step', async () =>{
      let p = agent.post(`/api/entry/${entryId}/increment`)
        .query({uid: uid, step: "one"})
        .set('Content-Type', 'application/json')
        .send({})

      // expect(p).to.be.rejectedWith('Bad Request')
      return p.should.eventually.be.rejectedWith('Bad Request')
    })

    it('invalid id', async () => {
      let p = agent.post(`/api/entry/graziemucho/increment`)
        .query({uid: uid, step: 2})
        .set('Content-Type', 'application/json')
        .send({})

      return p.should.eventually.be.rejectedWith('Bad Request')
    })

    it('unknown id', async () => {
      let p = agent.post(`/api/entry/59be6d917be69d3f8c6d870c/increment`)
        .query({uid: uid, step: 2})
        .set('Content-Type', 'application/json')
        .send({})

      return p.should.eventually.be.rejectedWith('Not Found')
    })
  })

})
