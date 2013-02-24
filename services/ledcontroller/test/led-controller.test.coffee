LEDController = require '../led-controller'


exports.LEDControllerTest =

  'test instantiation': (test) ->
    accumulator = new LEDController()
    test.done()
