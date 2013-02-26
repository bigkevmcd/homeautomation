MessageBus = (require 'homeauto').MessageBus
EventEmitter = (require 'events').EventEmitter
cosm = require 'cosm'

util = require 'util'

feedId = 106651
apiKey = 'WyH2xftcopAr8D8uAu24-x7ZlTiSAKxwSjNKS2RyTUtNMD0g'

lightingMapping =
    1: 'familyroom-light'

temperatureMapping =
    '28.645C18040000': 'office-temp'

class CosmLogger extends EventEmitter
    
  constructor: (@options = {}) ->
    @console = @options.console ?= console
    @process = @options.process ?= process
    @process.on 'SIGINT', () =>
      @close()
  close: () =>
    if @bus then @bus.close()

  run: () ->
    @bus = @options.bus?= @_createMessageBus(@options)
    @bus.on 'event', (topic, data) =>
      @handleEvent(data)

  pushToCosm: (stream, timestamp, value) ->
    @console.log "Pushing #{value} to #{stream}"
    client = new cosm.Cosm(apiKey)
    feed = new cosm.Feed(cosm,
      id: feedId
    )
    stream = new cosm.Datastream(client, feed,
      id: stream
    )
    stream.addPoint value, timestamp, (err, response, body) =>
      if err?
        @console.log "Received #{err}"
      else
        @console.log "Statuscode #{response.statusCode}"

  handleEvent: (data) ->
    timestamp = new Date(data.timestamp)
    if data.temperature?
      datastream = temperatureMapping[data.nodeid]
      if datastream?
        @pushToCosm(datastream, timestamp, data.temperature)
    if data.light?
      datastream = lightingMapping[data.nodeid]
      if datastream?
        @pushToCosm(datastream, timestamp, data.light)

  _createMessageBus: (options = {}) ->
    hostname = options.brokerHost
    bus = new MessageBus(
      subAddress: "tcp://#{hostname}:9999"
      subscribe: ['sensor']
      identity: "cosm-logger-#{@process.pid}"
    )
    bus

module.exports = CosmLogger
