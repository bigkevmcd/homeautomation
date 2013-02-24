OWFSRelay = require './owfs-relay'

owfsRelay = new OWFSRelay
    brokerHost: 'laurelin'
    path: '/mnt/one-wire'

owfsRelay.run()
