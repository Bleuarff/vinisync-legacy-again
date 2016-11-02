# vinisync
Plain simple cellar management

## Setup
Create *config/config.yml* with the following:

    server:
      port: 3001
      cluster: false
    db: mongodb://[user@host:port/dbname]

    session: # redis session details
      host: [rasteau]
      port: 7396
      duration: 3600 # session duration, in seconds
      appName: 'vinisync'

    auth:
      googleApiId: [googleapis's project id]


    log:
      level: debug
      output:
        -
          target: trace.log

Then:

    npm -g grunt-cli
    npm install
    grunt # runs local server
