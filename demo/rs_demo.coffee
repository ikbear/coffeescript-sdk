mime = require('mime')
qiniu = require('../index.coffee')

qiniu.conf.ACCESS_KEY =  '<Please apply your access key>'
qiniu.conf.SECRET_KEY = '<Dont send your secret key to anyone>'

friendName = key = __filename
bucket = "coffeescript_test_bucket"
domain = bucket + "qiniudn.com"

conn = new qiniu.digestauth.Client()

qiniu.rs.mkbucket conn, bucket, (resp) =>
  console.log "\n===> Make bucket result: ", resp
  if resp.code != 200
    return
  opts = 
    scope: bucket
    expires: 3600
    callbackUrl: null
    callbackBodyType: null
    customer: null
  token = new qiniu.auth.UploadToken(opts)
  uploadToken = token.generateToken()
  mimeType = mime.lookup(key)
  rs = new qiniu.rs.Service(conn, bucket)
  [localFile, customMeta, callbackParams, enableCrc32Check] = [key, "", {}, false]
  
  rs.uploadFileWithToken uploadToken, localFile, key, mimeType, customMeta, callbackParams, enableCrc32Check, (resp) ->
    console.log "\n===> Upload File with Token result: ", resp
    if resp.code != 200
      return
    rs.publish domain, (resp) ->
      console.log "\n===> Publish result: ", resp
      if resp.code != 200
        return
      rs.stat key, (resp) ->
        console.log "\n===> Stat result: ", resp
        if resp.code != 200
          return
        rs.get key, friendName, (resp) ->
          console.log "\n===> Get result: ", resp
          if resp.code != 200
            return
