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
    @includesMatchers = []
    @excludesMatchers = []

  resetPromises: ()->
    @files = null
    @folders = null

  include: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Including patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @includes.push pattern
      @includesMatchers[pattern] = new minimatch.Minimatch(pattern)
    @resetPromises()
    return this

  exclude: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Excluding patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @excludes.push pattern
      @excludesMatchers[pattern] = new minimatch.Minimatch(pattern)
    @resetPromises()
    return this

  resolvePattern: (pattern, basePath)->
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

  resolve: (basePath)->
    includedFileListPromises = (@resolvePattern(pattern, basePath) for pattern in @includes)
    excludedFileListPromises = (@resolvePattern(pattern, basePath) for pattern in @excludes)

    includedFilesPromise = Q.all(includedFileListPromises).then @merge
    excludedFilesPromise = Q.all(excludedFileListPromises).then @merge

    @files = Q.all([includedFilesPromise, excludedFilesPromise]).spread @subtract
    @folders = @files.then (files)->
      folders = []
      for file in files
        folder = path.dirname(file)
        folders.push(folder) if folder not in folders
      return folders
    return @files

  getFilesPromise: ()->
    @files

  getFoldersPromise: ()->
    @folders

  match: (filePath)->
    for matcher in @excludesMatchers
      return false if matcher.match(filePath)
    for matcher in @includesMatchers
      return true if matcher.match(filePath)
    return false

exports.FileList = FileList