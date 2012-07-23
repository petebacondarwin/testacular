Q = require('q')
glob = require('glob')
globQ = Q.nbind(glob)
util = require('./util')
log = require('./logger').create('file-list')
minimatch = require("minimatch")
path = require('path')

class FileList
  constructor: (patterns...)->
    @clear()
    @resetPromises()
    @include(patterns...)

  clear: ()->
    @includes = []
    @excludes = []

  resetPromises: ()->
    @files = null
    @folders = null

  include: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Including patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @includes.push pattern
    @resetPromises()
    return this

  exclude: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Excluding patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @excludes.push pattern
    @resetPromises()
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

  resolveFiles: (basePath)->
    includedFileListPromises = (@resolve(pattern, basePath) for pattern in @includes)
    excludedFileListPromises = (@resolve(pattern, basePath) for pattern in @excludes)

    includedFilesPromise = Q.all(includedFileListPromises).then @merge
    excludedFilesPromise = Q.all(excludedFileListPromises).then @merge

    @files = Q.all([includedFilesPromise, excludedFilesPromise]).spread @subtract

  resolveFolders: (basePath)->
    @files ?= @resolveFiles(basePath)
    @folders = []
    for file in @files
      folder = path.dirname(file)
      @folders.push(folder) if folder not in folders
    return @folders
    
  match: (filePath, basePath)->
    relPath = path.relative(filePath, basePath)
    for patterns in @excludes
      return false if minimatch(relPath, pattern)
    for patterns in @includes
      return true if minimatch(relPath, pattern)
    return false

exports.FileList = FileList