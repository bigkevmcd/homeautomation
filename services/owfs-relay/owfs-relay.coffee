BusClient = (require './busclient')
fs = require 'fs'
path = require 'path'
util = require 'util'
async = require 'async'


delay = (ms, func) -> setTimeout func, ms
trim = (string) -> string.replace(/^\s+|\s+$/g,'')


class OWFSRelay extends BusClient

    constructor: (@options = {}) ->
      super(@options)
      @pollTime = @options.time ?= 60000
      @owfsPath = @options.path
      @sensorValues = {}
      @counter = 0

    runService: () ->
      @watchSensors()

    # Returns true if the OWFS Family starts with 28 i.e. is DS18B20
    isTemperatureSensor: (name) ->
      /^28/.test(name)

    watchSensors: () =>
      @getSensorFiles (err, sensorIds) =>
        @processSensors(sensorIds)
        delay(@pollTime, @watchSensors)

    processSensors: (sensorIds, callback) =>
      async.each sensorIds, @processSensor, () ->
        if callback?
          callback()

    processSensor: (sensorId, callback) =>
      fullname = path.join(@owfsPath, sensorId, 'temperature')
      fs.readFile fullname, (err, value) =>
        if not err?
          value = trim(value.toString())
          if @sensorValues[sensorId] != value
            message =
              event: 'sensor'
              temperature: value
              timestamp: new Date()
              nodeid: sensorId
              counter: @counter++
            @bus.send message
            @sensorValues[sensorId] = value
          if callback?
             callback()

    getSensorFiles: (callback) ->
      sensorFiles = []
      fs.readdir @owfsPath, (err, filenames) =>
        for filename in filenames
          if @isTemperatureSensor(filename)
            sensorFiles.push filename
        callback(err, sensorFiles)

module.exports = OWFSRelay