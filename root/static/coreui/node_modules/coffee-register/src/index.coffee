Coffeescript = require 'coffee-script'
child_process = require 'child_process'
fs = require 'fs-jetpack'
path = require 'path'
md5 = require 'md5'
COFFEE_CACHE_DIR = if process.env.COFFEE_CACHE_DIR then path.resolve(process.env.COFFEE_CACHE_DIR) else path.join __dirname,'..','.cache'
COFFEE_NO_CACHE = process.env.COFFEE_NO_CACHE
serveCached = not COFFEE_NO_CACHE

## ==========================================================================
## require.extensions patch
## ========================================================================== 
register = (extensions)->
	targetExtensions = [].concat(extensions, '.coffee')
	fs.dir(COFFEE_CACHE_DIR)
	cachedFiles = fs.list(COFFEE_CACHE_DIR).filter (file)-> file.slice(-3) is '.js'

	loadFile = (module, filename)->
		content = fs.read(filename)
		hash = md5(content)
		cachedFile = "#{hash}.js"
		cachedFilePath = path.join COFFEE_CACHE_DIR,cachedFile

		if serveCached and cachedFiles.indexOf(cachedFile) isnt -1
			compiledContent = fs.read cachedFilePath
		else
			compiledContent = Coffeescript.compile content, {filename, bare:true, inlineMap:true}
			fs.write cachedFilePath, compiledContent
		
		module._compile compiledContent, filename


	for extension in targetExtensions when extension
		require.extensions[extension] = loadFile

	return register




## ==========================================================================
## child_process.fork patch
## ========================================================================== 
if child_process
	origFork = child_process.fork
	coffeeBinary = path.resolve './node_modules/coffee-script/bin/coffee'

	child_process.fork = (filePath, args, options)->
		if path.extname(filePath) is '.coffee'
			unless Array.isArray(args)
				options = args or {}
				args = []
			
			args = [filePath].concat args
			filePath = coffeeBinary
		
		origFork filePath, args, options



## ==========================================================================
## Source map support (necessary for cached files)
## ========================================================================== 
### istanbul ignore next ###
if process.env.SOURCE_MAPS or process.env.SOURCE_MAP
	require('@danielkalen/source-map-support').install(hookRequire:true)



module.exports = register()
