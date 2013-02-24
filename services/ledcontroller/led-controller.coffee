MessageBus = (require 'homeauto').MessageBus
EventEmitter = (require 'events').EventEmitter

serialport = require 'serialport'

serialOpt =
    baudrate: 9600,
    parser: serialport.parsers.readline('\n')


class LEDController extends EventEmitter

    subscriptions: ['receiver']

    constructor: (@options = {}) ->
      @console = @options.console ?= console
      @process = @options.process ?= process
      @messageQueue = []
      @process.on 'SIGINT', () =>
        @close()

      @on 'serial-ready', =>
        @bus.on 'event', (topic, data) =>
          console.log "Got message: #{JSON.stringify data}"
          if data.action?
            @handleLED(2, data) if data.action is "switch-on"
            @handleLED(1, data) if data.action is "switch-off"
      setTimeout(@processQueue, 200)

    processQueue: () =>
      result = @messageQueue.pop()
      if result?
        @console.log "Writing #{result} to the serial device"
        @serial.write(result, (error) => 
          if error?
            @console.log "Error writing #{error}"
        )
        setTimeout(@processQueue, 200)
      else
        setTimeout(@processQueue, 200)

    close: () =>
      if @bus then @bus.close()
      if @serial then @serial.close()

    handleLED: (status, options) ->
      pin = if options.pin? options.pin else 13
      @messageQueue.push("1/2/#{pin}/#{status}/")

    run: () ->
      @serial = @options.serial?= @_createSerial(@options)
      @bus = @options.bus?= @_createMessageBus(@options)

    _createSerial: (options) ->
      port = new serialport.SerialPort options.device, serialOpt
      port.on 'open', () =>
        port.flush () =>
            @emit 'serial-ready'
      port

    _createMessageBus: (options = {}) ->
      hostname = options.brokerHost
      bus = new MessageBus(
        subAddress: "tcp://#{hostname}:9999"
        pushAddress: "tcp://#{hostname}:8888"
        subscribe: @subscriptions
        identity: "led-controller-#{@process.pid}"
      )
      @emit 'bus-ready'
      bus

module.exports = LEDController
