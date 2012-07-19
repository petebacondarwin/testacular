#==============================================================================
# lib/file-list.js module
#==============================================================================
describe 'file-list', ->
  rewire = require 'rewire'
  Q = require('q')
  

  require('../test-util.js').disableLogger()

  FileListMod = FileList = fileList = null

  beforeEach ->
    FileListMod = rewire('../../lib/file-list')
    FileList = FileListMod.FileList
    fileList = new FileList

  afterEach ->
    rewire.reset()

  #============================================================================
  # FileList.include
  #============================================================================
  describe 'include', ->
    it 'should add a single included pattern to the @includes field', ->
      fileList.include 'x/y/z'
      expect(fileList.includes.length).toEqual(1)

    it 'should add multiple included patterns to the @includes field', ->
      fileList.include 'x/y/z', 'a/b/c'
      expect(fileList.includes.length).toEqual(2)

    it 'should add an array of included patterns to the @includes field', ->
      fileList.include ['x/y/z', 'a/b/c']
      expect(fileList.includes.length).toEqual(2)

  describe 'excludes', ->
    it 'should add a single excluded pattern to the @excludes field', ->
      fileList.exclude 'x/y/z'
      expect(fileList.excludes.length).toEqual(1)

    it 'should add multiple excluded patterns to the @excludes field', ->
      fileList.exclude 'x/y/z', 'a/b/c'
      expect(fileList.excludes.length).toEqual(2)

    it 'should add an array of excluded patterns to the @excludes field', ->
      fileList.exclude ['x/y/z', 'a/b/c']
      expect(fileList.excludes.length).toEqual(2)

  describe 'constructor', ->
    it 'should add no patterns with an empty constructor', ->
      fileList = new FileList 
      expect(fileList.includes.length).toEqual(0)

    it 'should add a single included pattern to the @includes field', ->
      fileList = new FileList 'x/y/z'
      expect(fileList.includes.length).toEqual(1)

    it 'should add multiple included patterns to the @includes field', ->
      fileList = new FileList 'x/y/z', 'a/b/c'
      expect(fileList.includes.length).toEqual(2)

    it 'should add an array of included patterns to the @includes field', ->
      fileList = new FileList ['x/y/z', 'a/b/c']
      expect(fileList.includes.length).toEqual(2)

  describe 'resolve', ->
    globQ = null
    resolve = null

    beforeEach ->
      # Mock up the globQ method
      globQ = jasmine.createSpy('globQ')
      FileListMod.__set__ 'globQ', globQ

      # Mock up the Q.resolve method
      resolve = jasmine.createSpy('Q.resolve')
      FileListMod.__set__ 'Q', resolve: resolve

    it 'should call Q.resolve with the pattern if the pattern is a url', ->
      pattern = 'http://www.google.com/some/path?seach=queryterms'
      promise = fileList.resolve(pattern)
      expect(globQ).not.toHaveBeenCalled()
      expect(resolve).toHaveBeenCalledWith([pattern])

    it 'should call globQ if given a non-url path ../../lib/*.js', ->
      pattern = '../../lib/*.js'
      promise = fileList.resolve(pattern, __dirname)
      expect(globQ).toHaveBeenCalledWith(pattern, cwd: __dirname)
      expect(resolve).not.toHaveBeenCalled()
  
      pattern = '/bin/non/existing.file'
      promise = fileList.resolve(pattern, __dirname)
      expect(globQ).toHaveBeenCalledWith(pattern, cwd: __dirname)
      expect(resolve).not.toHaveBeenCalled()

  describe 'subtract', ->
    it 'should return empty set if set1 is empty', ->
      expect(fileList.subtract([], []).length).toEqual(0)
      expect(fileList.subtract([], ['a']).length).toEqual(0)

    it 'should return empty set if set2 is the same as or contains set1', ->
      expect(fileList.subtract(['a', 'b'], ['a', 'b']).length).toEqual(0)
      expect(fileList.subtract(['a', 'b'], ['a', 'b', 'c']).length).toEqual(0)

    it 'should return a copy of set1 if set2 is empty', ->
      expect(fileList.subtract(['a', 'b'], [])).toEqual(['a','b'])

    it 'should return a an array containing only those elements of set1 that are not in set2, maintaining the order from set1', ->
      expect(fileList.subtract(['a', 'b', 'c', 'd'], ['d', 'b'])).toEqual(['a','c'])


  describe 'merge', ->
    it 'should return an array with no duplicates', ->
      expect(fileList.merge([['a','b','c'],['b','c'],['a','a'],['d']])).toEqual(['a','b','c','d'])
      expect(fileList.merge([['a'],['b'],['c'],['d']])).toEqual(['a','b','c','d'])
      expect(fileList.merge([['d'],['b','a'],[],['a','c']])).toEqual(['d','b','a','c'])
    
    it 'should return an emprty array if there are no items to merge', ->
      expect(fileList.merge([])).toEqual([])
      expect(fileList.merge([[],[],[],[]])).toEqual([])

  describe 'getFiles', ->
    it 'should merge the includes files and remove the excluded files', ->
      results = null
      runs ()->
        fileList.include ['../../lib/config.js','../../lib/*.js', '../../lib/*.coffee']
        fileList.exclude ['../../lib/file-list.js']
        fileList.getFiles(__dirname).then (files)-> results = files
      waitsFor ()->
        results?
      runs ()->
        expect(results.length).not.toEqual 0
        expect(results).toContain('../../lib/config.js')
        expect(results).not.toContain('../../lib/file-list.js')