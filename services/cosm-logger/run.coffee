CosmLogger = require './cosm-logger'

cosmLogger = new CosmLogger(
    brokerHost: '127.0.0.1'
)

cosmLogger.run()
