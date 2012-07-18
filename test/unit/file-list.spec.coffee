#==============================================================================
# lib/file-list.js module
#==============================================================================
describe 'file-list', ->
  util = require '../test-util.js'
  FileList = require('../../lib/file-list').FileList
  fileList = null

  beforeEach util.disableLogger
  beforeEach -> fileList = new FileList

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

  describe 'resolvePattern', ->
    it 'should return an absolute url unmodified', ->
      pattern = 'http://www.google.com/some/path?seach=queryterms'
      files = null
      runs ()->
        fileList.resolvePattern(pattern).then (results)->
          files = results
      waitsFor ()-> files?
      runs ()->
        expect(files[0]).toEqual pattern

    it 'should return an array of js files from the lib folder for a path ../../lib/*.js', ->
      pattern = '../../lib/*.js'
      files = null
      runs ()->
        fileList.resolvePattern(pattern, __dirname).then (results)->
          files = results
      waitsFor ()-> files?
      runs ()->
        expect(files.length).toBeGreaterThan(0)

  describe 'subtraction', ->
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
