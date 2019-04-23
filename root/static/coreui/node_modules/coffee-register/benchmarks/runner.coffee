Promise = require 'bluebird'
Benchmark = require 'benchmark'
benchmarks = require 'beautify-benchmark'
exec = require('child_process').execSync
fs = require 'fs-jetpack'
path = require 'path'
chalk = require 'chalk'
extend = require 'extend'
sample = ()-> path.join __dirname,'samples',arguments...
temp = ()-> path.join __dirname,'temp',arguments...
process.env.COFFEE_CACHE_DIR = COFFEE_CACHE_DIR = temp('.cache')

fs.dir temp(),empty:true


theImporter = null
runClean = (type)->
	deRegister()
	switch type
		when 'coffee-script/register' then require('coffee-script/register')
		when 'coffee-register' then require('../')

	theImporter()


deRegister = ()->
	delete require.extensions['.coffee']
	delete require.extensions['.litcoffee']
	delete require.extensions['.coffee.md']
	delete require.cache[require.resolve('coffee-script/register')]
	delete require.cache[require.resolve('coffee-script/lib/coffee-script/register')]
	delete require.cache[require.resolve('../')]
	samples = fs.list(sample())
	for sampleFile in samples
		delete require.cache[sample(sampleFile)]
	
	cached = fs.list(temp('.cache')) or []
	for cachedFile in cached
		delete require.cache[temp('.cache',cachedFile)]

	largeModules = Object.keys(require.cache).filter (path)-> path.includes('simplyimport') or path.includes('simplywatch')
	for item in largeModules
		delete require.cache[item]
	
	return


suite = (name, options)->
	Benchmark.Suite(name, options)
		.on 'start', ()-> console.log chalk.dim name
		.on 'cycle', ()-> benchmarks.add arguments[0].target
		.on 'complete', ()-> benchmarks.log()



suite('3 small modules', {
	onComplete: ()-> fs.dir temp(),empty:true
	onStart: ()->
		theImporter = ()->
			require('./samples/small1')
			require('./samples/small2')
			require('./samples/small3')
			return
})
	.add 'coffee-script/register', ()->
		runClean('coffee-script/register')

	.add 'coffee-register (uncached)', ()->
		process.env.COFFEE_NO_CACHE = true
		runClean('coffee-register')

	.add 'coffee-register (cached)', ()->
		delete process.env.COFFEE_NO_CACHE
		runClean('coffee-register')


	.run()



suite('6 small modules', {
	onComplete: ()-> fs.dir temp(),empty:true
	onStart: ()->
		theImporter = ()->
			require('./samples/small1')
			require('./samples/small2')
			require('./samples/small3')
			require('./samples/small4')
			require('./samples/small5')
			require('./samples/small6')

})
	.add 'coffee-script/register', ()->
		runClean('coffee-script/register')

	.add 'coffee-register (uncached)', ()->
		process.env.COFFEE_NO_CACHE = true
		runClean('coffee-register')

	.add 'coffee-register (cached)', ()->
		delete process.env.COFFEE_NO_CACHE
		runClean('coffee-register')


	.run()



suite('4 medium modules', {
	onComplete: ()-> fs.dir temp(),empty:true
	onStart: ()->
		theImporter = ()->
			require('./samples/medium1')
			require('./samples/medium2')
			require('./samples/medium3')
			require('./samples/medium4')

})
	.add 'coffee-script/register', ()->
		runClean('coffee-script/register')

	.add 'coffee-register (uncached)', ()->
		process.env.COFFEE_NO_CACHE = true
		runClean('coffee-register')

	.add 'coffee-register (cached)', ()->
		delete process.env.COFFEE_NO_CACHE
		runClean('coffee-register')


	.run()


suite('2 large modules', {
	onComplete: ()-> fs.dir temp(),empty:true
	onStart: ()->
		theImporter = ()->
			require('simplyimport/lib/simplyimport')
			require('simplywatch/lib/simplywatch')

})
	.add 'coffee-script/register', ()->
		runClean('coffee-script/register')

	.add 'coffee-register (uncached)', ()->
		process.env.COFFEE_NO_CACHE = true
		runClean('coffee-register')

	.add 'coffee-register (cached)', ()->
		delete process.env.COFFEE_NO_CACHE
		runClean('coffee-register')


	.run()
























