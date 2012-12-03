exports.mkMogrifyParams = (opts) ->
  paramsString = ""
  opts = opts ? {}
  keys = ["thumbnail", "gravity", "crop", "quality", "rotate", "format"] 
  for key in keys
    if opts[key]?
      paramsString += '/' + key + '/' + opts[key]
  if opts.auto_orient? && (opts.auto_orient == true)
    paramsString += '/auto-orient'
  'imageMogr' + paramsString

exports.mogrify = (sourceImgUrl, opts) ->
  sourceImgUrl + '?' + @mkMogrifyParams(opts)
