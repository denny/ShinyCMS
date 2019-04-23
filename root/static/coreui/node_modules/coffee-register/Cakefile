fs = require 'fs-jetpack'
Promise = require 'bluebird'
promiseBreak = require 'promise-break'
Coffeescript = require 'coffee-script'
md5 = require 'md5'
path = require 'path'
CACHE_DIR = path.resolve '.config','buildcache'

process.exit(0) if process.env.CI
fs.dir(CACHE_DIR)

compileCoffee = (srcFile, destFile)->
	Promise.resolve()
		.then ()-> fs.readAsync(srcFile)
		.then (src)->
			srcHash = md5(src)
			cacheDest = path.join(CACHE_DIR, "#{srcHash}.js")
			
			Promise.resolve()
				.then ()-> fs.existsAsync(cacheDest)
				.then (cacheExists)-> promiseBreak() if cacheExists
				.then ()-> console.log "Building #{srcFile}"
				.then ()-> Coffeescript.compile src, {bare:true}
				.then (output)-> fs.writeAsync cacheDest, output
				.catch promiseBreak.end
				.then ()-> fs.copyAsync cacheDest, destFile, overwrite:true


task 'build', 'compile lib, test, and benchmark files', ()->
	Promise.resolve()
		.then ()-> invoke 'build:lib'
		.then ()-> invoke 'build:test'
		.then ()-> invoke 'build:benchmark'


task 'build:lib', ()->
	compileCoffee 'src/index.coffee', 'lib/index.js'


task 'build:test', ()->
	compileCoffee 'test/test.coffee', 'test/test.js'


task 'build:benchmark', ()->
	compileCoffee 'benchmarks/runner.coffee', 'benchmarks/runner.js'

