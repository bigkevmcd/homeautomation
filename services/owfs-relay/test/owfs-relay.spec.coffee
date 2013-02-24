OWFSRelay = require '../owfs-relay'
fs = require 'fs'
temp = require 'temp'
path = require 'path'


describe 'OWFSRelay', ->

  beforeEach =>
    @testDir = temp.mkdirSync()

  afterEach (done) =>
    fs.readdir @testDir, (err, files) =>
      for file in files
        fs.unlinkSync path.join(@testDir, file)
      fs.rmdir @testDir, done

  createFileWithValue = (name, value, callback) =>
    fullPath = path.join(@testDir, name)
    fs.writeFile fullPath, value, (err) ->
      callback(err)

  it 'can be instantiated', (done) =>
    relay = new OWFSRelay()
    done()

  it 'can identify temperature sensors', (done) =>
    createFileWithValue '28.645C18041234', '12.625', (err) =>
      createFileWithValue '81.645C18043214', '12.625', (err) =>
        createFileWithValue '28.645C18043214', '12.625', (err) =>
          relay = new OWFSRelay(
              brokerHost: 'testing'
              path: @testDir
          )
          relay.getSensorFiles( (err, files) =>
            expect(files).toEqual(['28.645C18041234', '28.645C18043214'])
            done()
          )
