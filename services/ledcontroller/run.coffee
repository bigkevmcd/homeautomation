LEDController = require './led-controller'

ledController = new LEDController(
    brokerHost: 'laurelin'
    device: '/dev/ttyUSB0'
)

delay = (ms, cb) -> setTimeout cb, ms

ledController.run()

ledController.on 'serial-ready', () =>
  console.log 'Sending a message'
  ledController.handleLED(
    2,
    pin: 13
  )


#  ledController.handleLED(
#    1,
#    pin: 13
#  )
#
  delay 3000, ->
    ledController.handleLED(
      1,
      pin: 13
    )
