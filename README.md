# vinisync
Plain simple cellar management

## Setup
Create *config/config.yml* with the following:

    server:
      port: 3001
      cluster: false
    db: mongodb://[user@host:port/dbname]

    session: # redis session details
      host: [redis_host]
      port: 7396
      duration: 3600 # session duration, in seconds
      appName: vinisync

    auth:
      googleApiId: [googleapis's project id]

    log:
      level: debug
      output:
        -
          target: trace.log

    # path to directory where images are saved. Must exist.
    imageDirectory: /home/bleuarff/dev/vni_images  

Then:

    npm install -g grunt-cli bower polymer-cli
    npm install
    cd assets && bower install
    grunt # runs local server

## SSL Setup

Use let's encrypt, see https://certbot.eff.org/#ubuntuxenial-nginx

    letsencrypt certonly --webroot -w /var/www/example -d example.com -d www.example.com -w /var/www/thing -d thing.is -d m.thing.is

*nginx.conf* contains a location that points to an accessible path where challenges are stored.

### Renewal

Set up cron job, twice a day:

    letsencrypt renew
