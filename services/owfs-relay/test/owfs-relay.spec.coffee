OWFSRelay = require '../owfs-relay'
fs = require 'fs'
temp = require 'temp'
path = require 'path'


# Based on https://gist.github.com/fjakobs/443774
# Removes a directory tree starting at the supplied root path
rmTreeSync = (root) ->
  return
  if not fs.existsSync(root)
    return
 
  files = fs.readdirSync(root)

  if not files.length
    fs.rmdirSync(root)
    return
  
  for file in files
    fullName = path.join(root, file)
    if fs.statSync(fullName).isDirectory()
      rmTreeSync(fullName)
    fs.unlinkSync(fullName)
  fs.rmdirSync(root)


class FakeMessageBus

  constructor: () ->
    @messages = []
    @closed = false

  send: (message) ->
    @messages.push message

  close: () ->
    @closed = true

describe 'OWFSRelay', ->

  beforeEach (done) =>
    @testDir = temp.mkdirSync()
    done()

  afterEach (done) =>
    rmTreeSync(@testDir)
    done()

  # We use synchronous versions to simplify this code
  createFileWithValue = (filePath, name, value, callback) =>
    sensorPath = path.join(@testDir, filePath)
    if not fs.existsSync(sensorPath)
      fs.mkdirSync(sensorPath)

    fullPath = path.join(sensorPath, name)
    fs.writeFile fullPath, value, (err) ->
      callback(err)

  it 'can be instantiated', (done) =>
    relay = new OWFSRelay()
    done()

  describe 'isTemperatureSensor', (done) =>
    beforeEach (done) =>
      @relay = new OWFSRelay()
      done()

    it 'should return true if the name looks like a DS18B20 sensor', (done) =>
      expect(@relay.isTemperatureSensor('28.645C18041234')).toBeTruthy()
      done()

    it 'should return true if the name looks like a DS18B20 sensor', (done) =>
      expect(@relay.isTemperatureSensor('81.645C18041234')).toBeFalsy()
      done()

  describe 'getSensorFiles', (done) =>
    it 'can identify temperature sensors', (done) =>
      createFileWithValue '28.645C18041234', 'temperature', '12.625', (err) =>
        expect(err).toBeFalsy()
        createFileWithValue '81.645C18043214', 'temperature', '12.625', (err) =>
          expect(err).toBeFalsy()
          createFileWithValue '28.645C18043214', 'temperature', '12.625', (err) =>
            expect(err).toBeFalsy()
            relay = new OWFSRelay(
                brokerHost: 'testing'
                path: @testDir
            )
            relay.getSensorFiles( (err, files) =>
              files.sort()
              expect(files).toEqual(['28.645C18041234', '28.645C18043214'])
              done()
            )

  describe 'processSensor', (done) =>
    beforeEach (done) =>
      @fakeBus = new FakeMessageBus()
      @relay = new OWFSRelay(
        brokerHost: 'testing'
        path: @testDir
        bus: @fakeBus
      )
      done()

    it 'should send messages to the bus when it detects a new sensor', (done) =>
      createFileWithValue '28.645C18041234', 'temperature', '12.625', (err) =>
        @relay.processSensor '28.645C18041234', () =>
          expect(@fakeBus.messages.length).toBe(1)
          message = @fakeBus.messages[0]
          expect(message.event).toBe('sensor')
          expect(message.temperature).toBe('12.625')
          expect(message.nodeid).toBe('28.645C18041234')
          expect(message.counter).toBe(0)
          done()

    it 'should not send a message to the bus when the value does not change', (done) =>
      createFileWithValue '28.645C18041234', 'temperature', '12.625', (err) =>
        @relay.processSensor '28.645C18041234', () =>
          expect(@fakeBus.messages.length).toBe(1)
          @relay.processSensor '28.645C18041234', () =>
            expect(@fakeBus.messages.length).toBe(1)
            done()

    it 'should send a message to the bus when the value changes', (done) =>
      createFileWithValue '28.645C18041234', 'temperature', '12.625', (err) =>
        @relay.processSensor '28.645C18041234', () =>
          expect(@fakeBus.messages.length).toBe(1)
          createFileWithValue '28.645C18041234', 'temperature', '12.000', (err) =>
            @relay.processSensor '28.645C18041234', () =>
              expect(@fakeBus.messages.length).toBe(2)
              done()


  describe 'processSensors', (done) =>
    beforeEach (done) =>
      @relay = new OWFSRelay(
        brokerHost: 'testing'
        path: @testDir
      )
      done()

    it 'should call processSensor for each sensorId', (done) =>
      processedIds = []
      testSensorIds = ['28.645C18041234', '28.12345678']
      @relay.processSensor = (sensorId) =>
        processedIds.push sensorId
      @relay.processSensors testSensorIds
      expect(processedIds).toEqual(testSensorIds)
      done()