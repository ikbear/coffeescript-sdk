fs = require 'fs'
mime = require 'mime'
crypto = require 'crypto'
crc32 = require 'crc32'

exports.base64ToUrlsafe = (value) ->
  value.replace(/\//g, '_').replace(/\+/g, '-')

exports.encode = (value) ->
  encoded = new Buffer(value or '').toString('base64')
  @base64ToUrlsafe(encoded) 

exports.generateActionString = (localFile, bucket, key, mimeType, customMeta, enableCrc32Check) ->
  return if not fs.existsSync(localFile)
  if not key?
    today = new Date
    key = crypto.createHash('sha1').update(localFile + today.toString()).digest('hex')
  entryUri = bucket + ":" + key
  mimeType = mimeType ? (mime.lookup(localFile) ? "application/octet-stream")
  actionParams = '/rs-put/' + @encode(entryUri) + '/mimeType/' + @encode(mimeType)
  if customMeta?
    actionParams += 'meta' + @encode(customMeta)
  if enableCrc32Check
    fileStat = fs.statSync(localFile)
    fileSize = fileStat.size
    buf = new Buffer(fileSize)
    fd = fs.open(localFile, 'r')
    fs.readSync(fd, buf, 0, fileSize, 0)
    fileCrc32 = parseInt("0x" + crc32(buf)).toString()
    actionParams += "/crc32/" + fileCrc32
  actionParams

exports.generateQueryString = (params) ->
  return params if params.constructor == String
  paramsString = []
  for  key, value of params
    paramsString.push(escape(key) + "=" + escape(params[key]))
  if paramsString.length > 0
    paramsString.join("&")
  else
    ""
exports.readAll = (strm, ondata) ->
  [out, total] = [[], 0]
  strm.on 'data', (chunk) ->
    out.push chunk
    total += chunk.length
    return

  strm.on 'end', () ->
    switch out.length
      when 0 then data = new Buffer(0)
      when 1 then data = out[0]
      else
        data = new Buffer(total)
        pos = 0
        for chunk in out
          chunk.copy data, pos
          pos += chunk.length
    ondata(data)
    return
  return

class Binary
  constructor: (@stream, @bytes) ->
exports.Binary = Binary

class Form
  constructor: (@stream, @contentType) ->
exports.Form = Form
