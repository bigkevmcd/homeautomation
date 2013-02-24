MessageBus = (require 'homeauto').MessageBus
EventEmitter = (require 'events').EventEmitter
fs = require 'fs'
path = require 'path'
util = require 'util'

locationMapping =
    1: 'family-room',

delay = (ms, func) -> setTimeout func, ms
trim = (string) -> string.replace(/^\s+|\s+$/g,'')

class OWFSRelay extends EventEmitter

    constructor: (@options = {}) ->
      @console = @options.console ?= console
      @process = @options.process ?= process
      @watch = @options.watch ?= fs.watch
      @pollTime = @options.time ?= 60000
      @owfsPath = @options.path
      @sensorValues = {}
      @counter = 0
      @process.on 'SIGINT', () =>
        @close()

    close: () =>
      if @bus then @bus.close()

    run: () ->
      @bus = @options.bus?= @_createMessageBus(@options)
      @watchSensors()

    # Returns true if the OWFS Family starts with 28 i.e. is DS18B20
    isTemperatureSensor: (name) ->
      /^28/.test(name)

    watchSensors: () =>
      @getSensorFiles (err, sensorIds) =>
        for sensorId in sensorIds
          fullname = path.join(@owfsPath, sensorId, 'temperature')
          fs.readFile fullname, (err, value) =>
            if not err?
              value = trim(value.toString())
              if @sensorValues[sensorId] != value
                console.log "Updating #{sensorId} to #{value}"
                message =
                  event: 'sensor'
                  temperature: value
                  timestamp: new Date()
                  nodeid: sensorId
                  counter: @counter++
                @bus.send message
                @sensorValues[sensorId] = value
        delay(@pollTime, @watchSensors)

    getSensorFiles: (callback) ->
      sensorFiles = []
      fs.readdir @owfsPath, (err, filenames) =>
        for filename in filenames
          if @isTemperatureSensor(filename)
            sensorFiles.push filename
        callback(err, sensorFiles)

    _createMessageBus: (options = {}) ->
      hostname = options.brokerHost
      new MessageBus(
        subAddress: "tcp://#{hostname}:9999"
        pushAddress: "tcp://#{hostname}:8888"
        identity: "owfs-relay-#{@process.pid}"
      )

module.exports = OWFSRelay
