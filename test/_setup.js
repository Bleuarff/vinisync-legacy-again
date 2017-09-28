const db = require('node-db-connector')

before('DB connection', () => {
  // use test db with alias name
  return db.init([{connectionString: 'mongodb://localhost:27017/vni-test', name: 'vni'}])
})

// empty test collections
after('close DB', async () => {
  var colls = ['wines', 'appellations', 'producers', 'cepages'],
      proms = []

  colls.forEach(coll => proms.push(db.vni.collection(coll).deleteMany()))
  await Promise.all(proms)
  return db.close()
})
