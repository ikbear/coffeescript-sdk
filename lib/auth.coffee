crypto = require 'crypto'
conf = require './conf.coffee'
util = require './util.coffee'

class UploadToken

  constructor: (@scope = null, @expires = 3600, @callbackUrl = null, @callbackBodyType = null, @customer = null) ->

  generateSignature: ->
    params = 
      scope: @scope
      deadline: @expires + Math.floor(Date.now() / 1000)
      callbackUrl: @callbackUrl
      callbackBodyType: @callbackBodyType
      customer: @customer
    paramsString = JSON.stringify params
    util.encode(paramsString) 

  generateEncodedDigest: (signature) ->
    hmac = crypto.createHmac('sha1', conf.SECRET_KEY)
    hmac.update(signature) 
    digest = hmac.digest('base64') 
    util.base64ToUrlsafe(digest) 

  generateToken: =>
    signature = @generateSignature()
    encodedDigest = @generateEncodedDigest(signature) 
    conf.ACCESS_KEY + ":" + encodedDigest + ":" + signature

exports.UploadToken = UploadToken 
