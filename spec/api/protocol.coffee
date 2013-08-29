assert = require 'assert'
ipc = require 'ipc'
remote = require 'remote'
protocol = remote.require 'protocol'

describe 'protocol API', ->
  describe 'protocol.registerProtocol', ->
    it 'throws error when scheme is already registered', ->
      register = -> protocol.registerProtocol('test1', ->)
      register()
      assert.throws register, /The scheme is already registered/
      protocol.unregisterProtocol 'test1'

    it 'calls the callback when scheme is visited', (done) ->
      protocol.registerProtocol 'test2', (url, referrer) ->
        assert.equal url, 'test2://test2'
        assert.equal referrer, window.location.toString()
        protocol.unregisterProtocol 'test2'
        done()
      $.get 'test2://test2', ->

  describe 'protocol.unregisterProtocol', ->
    it 'throws error when scheme does not exist', ->
      unregister = -> protocol.unregisterProtocol 'test3'
      assert.throws unregister, /The scheme has not been registered/

  describe 'registered protocol callback', ->
    it 'returns string should send the string as request content', (done) ->
      handler = remote.createFunctionWithReturnValue 'valar morghulis'
      protocol.registerProtocol 'atom-string', handler

      $.ajax
        url: 'atom-string://fake-host'
        success: (data) ->
          assert.equal data, handler()
          protocol.unregisterProtocol 'atom-string'
          done()
        error: (xhr, errorType, error) ->
          assert false, 'Got error: ' + errorType + ' ' + error
          protocol.unregisterProtocol 'atom-string'

    it 'returns RequestStringJob should send string', (done) ->
      data = 'valar morghulis'
      job = new protocol.RequestStringJob(mimeType: 'text/html', data: data)
      handler = remote.createFunctionWithReturnValue job
      protocol.registerProtocol 'atom-string-job', handler

      $.ajax
        url: 'atom-string-job://fake-host'
        success: (response) ->
          assert.equal response, data
          protocol.unregisterProtocol 'atom-string-job'
          done()
        error: (xhr, errorType, error) ->
          assert false, 'Got error: ' + errorType + ' ' + error
          protocol.unregisterProtocol 'atom-string-job'

    it 'returns RequestFileJob should send file', (done) ->
      job = new protocol.RequestFileJob(__filename)
      handler = remote.createFunctionWithReturnValue job
      protocol.registerProtocol 'atom-file-job', handler

      $.ajax
        url: 'atom-file-job://' + __filename
        success: (data) ->
          content = require('fs').readFileSync __filename
          assert.equal data, String(content)
          protocol.unregisterProtocol 'atom-file-job'
          done()
        error: (xhr, errorType, error) ->
          assert false, 'Got error: ' + errorType + ' ' + error
          protocol.unregisterProtocol 'atom-file-job'

  describe 'protocol.isHandledProtocol', ->
    it 'returns true if the scheme can be handled', (done) ->
      assert.equal protocol.isHandledProtocol('file'), true
      assert.equal protocol.isHandledProtocol('http'), true
      assert.equal protocol.isHandledProtocol('https'), true
      assert.equal protocol.isHandledProtocol('atom'), false
