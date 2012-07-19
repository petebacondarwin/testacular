Q = require('q')
glob = require('glob')
globQ = Q.nbind(glob)
util = require('./util')
log = require('./logger').create('file-list')

class FileList
  constructor: (patterns...)->
    @clear()
    @include(patterns...)

  clear: ()->
    @includes = []
    @excludes = []

  include: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Including patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @includes.push pattern
    return this

  exclude: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Excluding patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @excludes.push pattern
    return this

  resolve: (pattern, basePath)->
    if util.isUrlAbsolute(pattern)
      Q.resolve([pattern])
    else
      globQ(pattern, cwd: basePath)

  merge: (fileLists)->
    files = []
    for fileList in fileLists
      for file in fileList when file not in files
        files.push(file)
    return files

  subtract: (set1, set2)->
    item for item in set1 when item not in set2

  getFiles: (basePath)->
    includedFileListPromises = (@resolve(pattern, basePath) for pattern in @includes)
    excludedFileListPromises = (@resolve(pattern, basePath) for pattern in @excludes)

    includedFilesPromise = Q.all(includedFileListPromises).then @merge
    excludedFilesPromise = Q.all(excludedFileListPromises).then @merge

    promise = Q.all([includedFilesPromise, excludedFilesPromise]).spread @subtract

exports.FileList = FileList