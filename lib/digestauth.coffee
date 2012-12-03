uri = require 'url'
http = require 'http'
https = require 'https'
crypto = require 'crypto'
querystring = require 'querystring'
conf = require './conf.coffee'
util = require './util.coffee'

checksum = (opt, body) ->
  hmac = crypto.createHmac 'sha1', conf.SECRET_KEY
  hmac.update(opt.path + "\n")
  if body?
    hmac.update(body)
  digest = hmac.digest 'base64'
  util.base64ToUrlsafe digest

class Client
  
  execute: (options, url, params, onresp, onerror) ->
    u = uri.parse url

    opt = 
      method: 'POST'
      port: u.port
      path: u.path
      host: u.hostname
      headers: 
        "Accept": 'application/json'
        "Accept-Encoding": 'gzip, deflate'

    if u.protocol == 'https:'
      proto = https
    else
      proto = http

    [isStream, contentLength, contentType] = [false, 0, 'application/x-www-form-urlencoded']
  
    if params?
      if params instanceof util.Binary
        [contentType, contentLength, isStream] = ['application/octet-stream', params.bytes, true]
      else if params instanceof util.Form
        [contentType, contentLength, isStream] = [params.contentType, null, true]
      else
        body = if typeof params == 'string' then params else querystring.stringify(params)
        contentLength = body.length
    
    opt.headers['Content-Type'] = contentType
    if contentLength?
      opt.headers['Content-Length'] = contentLength
    if options.UploadSignatureToken?
      opt.headers['Authorization'] = 'UpToken ' + options.UploadSignatureToken
    if options.AccessToken?
      opt.headers['Authorization'] = 'Bearer ' + options.AccessToken
    else
      opt.headers['Authorization'] = 'QBox ' + conf.ACCESS_KEY + ':' + checksum(opt, body)

    req = proto.request(opt, onresp) 
    req.on('error', onerror)
    if params?
      if isStream
        params.stream.pipe(req)
      else
        req.end(params)
    else
      req.end()
    return req

  _callWith: (options, url, params, onret) ->
    onresp = (res) ->
      util.readAll res, (data) ->
        if data.length == 0
          ret = { code: res.statusCode }
          if res.statusCode == 200
            ret.error = 'E' + res.statusCode
          onret ret
          return
        try
          ret = JSON.parse data
          if res.statusCode == 200
            ret = { code: 200, data: ret }
          else
            ret.code = res.statusCode
        catch e
          ret = { code: -1, error: e.toString(), detail: e }
        onret ret

    onerror = (e) ->
      ret = { code: -1, error: e.message, detail: e }
      onret(ret)
      
    @execute(options, url, params, onresp, onerror)


  callWith: (url, params, onret) ->
    @_callWith("", url, params, onret)

  callWithToken: (uploadToken, url, params, onret) ->
    options = { UploadSignatureToken: uploadToken }
    @_callWith(options, url, params, onret)

exports.Client = Client
