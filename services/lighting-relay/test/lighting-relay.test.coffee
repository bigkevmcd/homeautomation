LightingRelay = require '../lighting-relay'


exports.LightingRelayTest =

  'test instantiation': (test) ->
    accumulator = new LightingRelay()
    test.done()
