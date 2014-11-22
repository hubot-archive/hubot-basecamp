chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'basecamp', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/basecamp')(@robot)

  it 'responds with what this does', ->
    expect(@robot.respond).to.have.been.calledWith(/basecamp/)

  it 'expands todos and messages', ->
    expect(@robot.hear).to.have.been.calledWith(/https:\/\/basecamp\.com\/(\d+)\/projects\/(\d+)/)
