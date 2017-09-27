const db = require('node-db-connector')

before('DB connection', () => {
  // use test db with alias name
  return db.init([{connectionString: 'mongodb://localhost:27017/vni-test', name: 'vni'}])
})

after('close DB', () => {
  return db.close()
})
