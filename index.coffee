libpath = if process.env.QINIU_COV then './lib-cov' else './lib'

module.exports = 
  conf: require(libpath + '/conf.coffee')
  digestauth: require(libpath + '/digestauth.coffee')
  rs: require(libpath + '/rs.coffee')
  img: require(libpath + '/img.coffee')
  auth: require(libpath + '/auth.coffee')
