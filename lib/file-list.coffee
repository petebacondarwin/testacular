Q = require('q')
glob = require('glob')
globQ = Q.nbind(glob)
util = require('./util')
log = require('./logger').create('file-list')

class FileList
  constructor: (patterns...)->
    @includes = []
    @excludes = []
    @include(patterns...)

  include: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Including patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @includes.push pattern
    return patterns

  exclude: (patterns...)->
    patterns = patterns[0] if Array.isArray(patterns[0])
    log.info('Excluding patterns:', patterns) if patterns.length > 0
    for pattern in patterns
      @excludes.push pattern
    return patterns

  resolvePattern: (pattern, basePath)->
    if util.isUrlAbsolute(pattern)
      console.log 'resolvePattern', Q.resolve
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

  getFiles: ()->
    includedFiles = resolvePattern(pattern) for pattern in @includes
    excludedFiles = resolvePattern(pattern) for pattern in @excludes
    subtract(includedFiles, excludedFiles)

exports.FileList = FileList