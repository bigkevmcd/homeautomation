LightingRelay = require './lighting-relay'

lightRelay = new LightingRelay(
    brokerHost: 'laurelin'
    device: '/dev/ttyACM0'
)

lightRelay.run()
