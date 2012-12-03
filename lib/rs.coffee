fs = require 'fs'
crc = require 'crc'
path = require 'path'
mime = require 'mime'
formstream = require 'formstream'
conf = require './conf.coffee'
util = require './util.coffee'
img = require './img.coffee'


exports.mkbucket = (conn, bucketname, onret) ->
  url = conf.RS_HOST + '/mkbucket/' + bucketname
  conn.callWith url, null, onret

class Service

  constructor: (@conn, @bucket) ->

  buckets: (onret) ->
    url = conf.RS_HOST + '/buckets'
    @conn.callWith url, null, onret

  putAuth: (onret) ->
    url = conf.IO_HOST + '/put-auth/'
    @conn.callWith url, null, onret

  putAuthEx: (expires, callbackUrl, onret) ->
    url = conf.IO_HOST + '/put-auth/' + expires + '/callback/' + utll.encode(callbackUrl)
    @conn.callWith url, null, onret
  
  put: (key, mimeType, fp, bytes, onret) ->
    mimeType = mimeType ? 'application/octet-stream'
    entryURI = @bucket + ':' + key
    url = conf.IO_HOST + '/rs-put/' + util.encode(entryURI) + '/mimeType/' + util.encode(mimeType)
    binary = new util.Binary(fp, bytes)
    @conn.callWith url, binary, onret

  putFile: (key, mimeType, localFile, onret) ->
    mimeType = mimeType ? mime.lookup localFile
    fs.stat localFile, (err, fi) =>
      if err 
        onret({ code: -1, error: err.toString, detail: err })
      fp = fs.createReadString(localFile)
      @put key, mimeType, fp, fi.size, onret
  
  upload: (upToken, key, mimeType, filename, stream, onret) ->
    mimeType = mimeType ? mime.lookup(filename)
    entryURI = @bucket + ':' + key
    url = '/rs-put/' + util.encode(entryURI) + '/mimeType/' + util.encode(mimeType)
    form = formstream()
    form.field 'action', url
    form.stream 'file', stream, filename, mimeType
    form = new util.Form(form, form.headers()['Content-Type'])
    @conn.callWith upToken, form, onret

  uploadFile: (upToken, key, mimeType, localFile, onret) ->
    fs.stat localFile, (err, fi) =>
      if err?
        onret({ code: -1, error: err.toString, detail: err })
        return
      filename = path.basename localFile
      stream = fs.createReadStream localFile
      @upload(upToken, key, mimeType, filename, stream, onret)

  uploadWithToken: (upToken, localFile, stream, key, mimeType, customMeta, callbackParams, enableCrc32Check, onret) ->
    bucket = @bucket
    mimeType = mimeType ? mime.lookup localFile
    actionString = util.generateActionString localFile, bucket, key, mimeType, customMeta, enableCrc32Check
    callbackParams = callbackParams ? { bucket: bucket, key: key, mime_type: mimeType }
    callbackQueryString = util.generateQueryString callbackParams
    url = conf.UP_HOST + '/upload'
    filename = path.basename localFile
    form = formstream()
    mimeType = mime.lookup localFile
    form.field 'auth', upToken
    form.field 'multipart', true
    form.field 'action', actionString
    form.field 'params', callbackQueryString
    form.stream 'file', stream, filename, mimeType
    form = new util.Form(form, form.headers()['Content-Type'])
    @conn.callWithToken upToken, url, form, onret

  uploadFileWithToken: (upToken, localFile, key, mimeType, customMeta, callbackParams, enableCrc32Check, onret) =>
    fs.stat localFile, (err, fi) =>
      if err?
        onret({ code: -1, error: err.toString, detail: err })
        return
      stream = fs.createReadStream localFile
      @uploadWithToken upToken, localFile, stream, key, mimeType, customMeta, callbackParams, enableCrc32Check, onret
  
  get: (key, attName, onret) ->
    entryURI = @bucket + ':' + key
    url = conf.RS_HOST + '/get/' + util.encode(entryURI) + '/attName/' + util.encode(attName)
    @conn.callWith url, null, onret
 
  getIfNotModified: (key, attName, base, onret) ->
    entryURI = @bucket + ':' + key
    url = conf.RS_HOST + '/get/' + util.encode(entryURI) + '/attName/' + util.encode(attName) + '/base/' + base
    @conn.callWith url, null, onret

  stat: (key, onret) ->
    entryURI = @bucket + ':' + key
    url = conf.RS_HOST + '/stat/' + util.encode(entryURI)
    @conn.callWith url, null, onret

  publish: (domain, onret) ->
    url = conf.RS_HOST + '/publish/' + util.encode(domain) + '/from/' + @bucket
    @conn.callWith url, null, onret

  unpublish: (domain, onret) ->
    url = conf.RS_HOST + '/unpublish/' + util.encode(domain)
    @conn.callWith url, null, onret

  remove: (key, onret) ->
    entryURI = @bucket + ':' + key
    url = conf.RS_HOST + '/delete/' + util.encode(entryURI)
    @conn.callWith url, null, onret

  drop: (onret) ->
    url = conf.RS_HOST + '/drop/' + @bucket
    @conn.callWith url, null, onret

  saveAs: (key, sourceURL, opWithParams, onret) ->
    destEntryURI = @bucket + ':' + key
    saveAsEntryURI = util.encode(destEntryURI)
    saveAsParam = '/save-as/' + saveAsEntryURI
    url = sourceURL + '?' + opWithParams + saveAsParam
    @conn.callWith url, null, onret

  imageMogrifyAs: (key, sourceImgURL, opts, onret) ->
    mogirfyParams = img.mkMogrifyParams opts
    @saveAs(key, sourceImgURL, mogrifyParams, onret)

  setProtected: (protectedMode, onret) ->
    url = conf.PUB_HOST + '/accessMode/' + @bucket + '/mode/' + protectedMode
    @conn.callWith url, null, onret

  setSeparator: (sep, onret) ->
    sep = util.encode sep
    url = conf.PUB_HOST + '/separator/' + @bucket + '/sep/' + sep
    @conn.callWith url, null, onret

  setStyle: (name, style, onret) ->
    name = util.encode name
    style = util.encode style
    url = conf.PUB_HOST + '/style/' + @bucket + '/name/' + name + '/style/' + style
    @conn.callWith url, null, onret

  unsetStyle: (name, onret) ->
    name = util.encode name
    url = conf.PUB_HOST + 'unstyle' + @bucket + '/name/' + name
    @conn.callWith url, null, onret

exports.Service = Service
