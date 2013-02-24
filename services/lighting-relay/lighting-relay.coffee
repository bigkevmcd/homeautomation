MessageBus = (require 'homeauto').MessageBus
EventEmitter = (require 'events').EventEmitter

serialport = require 'serialport'

locationMapping =
    1: 'family-room',

serialOpt =
    baudrate: 9600,
    parser: serialport.parsers.readline('\n')


class LightingRelay extends EventEmitter

    constructor: (@options = {}) ->
      @console = @options.console ?= console
      @process = @options.process ?= process
      @process.on 'SIGINT', () =>
        @close()

      @on 'ready', () =>
        @serial.on 'data', (data) =>
          @console.log "Got: #{data}"
          try
            jdata = JSON.parse data
            jdata.event = 'sensor'
            jdata.timestamp = new Date()
            if jdata.nodeid? and locationMapping[jdata.nodeid]?
              jdata.location = locationMapping[jdata.nodeid]
            else
              jdata.location = 'unknown'
            @bus.send jdata
          catch err
            console.log 'Err.. data is not json'

    close: () =>
      if @bus then @bus.close()
      if @serial then @serial.close()

    run: () ->
      @serial = @options.serial?= @_createSerial(@options)
      @bus = @options.bus?= @_createMessageBus(@options)

    _createSerial: (options) ->
      port = new serialport.SerialPort options.device, serialOpt
      port.on 'open', () =>
        port.flush () =>
            @emit 'ready'
      port

    _createMessageBus: (options = {}) ->
      hostname = options.brokerHost
      new MessageBus(
        subAddress: "tcp://#{hostname}:9999"
        pushAddress: "tcp://#{hostname}:8888"
        identity: "lighting-relay-#{@process.pid}"
      )


module.exports = LightingRelay

# node-getopt oneline example.
# opt = require('node-getopt').create([
#   ['s' , ''                    , 'short option.'],
#   [''  , 'long'                , 'long option.'],
#   ['S' , 'short-with-arg=ARG'  , 'option with argument'],
#   ['L' , 'long-with-arg=ARG'   , 'long option with argument'],
#   [''  , 'color[=COLOR]'       , 'COLOR is optional'],
#   ['m' , 'multi-with-arg=ARG+' , 'multiple option with argument'],
#   [''  , 'no-comment'],
#   ['h' , 'help'                , 'display this help'],
#   ['v' , 'version'             , 'show version']
# ])              // create Getopt instance
# .bindHelp()     // bind option 'help' to default action
# .parseSystem(); // parse command line

# console.info(opt);
