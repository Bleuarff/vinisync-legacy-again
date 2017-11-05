const db = require('node-db-connector')

before('DB connection', async () => {
  // use test db with alias name
  await db.init([{connectionString: 'mongodb://localhost:27017/vni-test', name: 'vni'}])
  return cleanAll()
})

// empty test collections
after('close DB', async () => {
  // await cleanAll()
  return db.close()
})

// clean all documents from listed collections
function cleanAll(){
  var colls = ['wines', 'appellations', 'producers', 'cepages', 'entries', 'users'],
      proms = []

  colls.forEach(coll => proms.push(db.vni.collection(coll).deleteMany()))
  return Promise.all(proms)
}
