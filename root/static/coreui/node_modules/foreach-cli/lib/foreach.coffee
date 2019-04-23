fs = require('fs')
path = require('path')
glob = require('glob')
chalk = require('chalk')
Listr = require '@danielkalen/listr'
exec = require('child_process').exec
regEx = require './regex'


module.exports = (options)-> new Promise (finish)->
	finalLogs = 'log':{}, 'error':{}
	globOptions = {}
	if options.ignore then globOptions.ignore = options.ignore
	if options.nodir then globOptions.nodir = options.nodir

	glob options.glob, globOptions, (err, files)-> if err then return console.error(err) else
		tasks = new Listr files.map((file)=>
			title: "Executing command: #{chalk.dim(file)}"		
			task: ()=> executeCommand(file)
		), options # same as {concurrent:options.concurrent}

		tasks.run().then(outputFinalLogs, outputFinalLogs)



	executeCommand = (filePath)-> new Promise (resolve, reject)->
		pathParams = path.parse path.resolve(filePath)
		pathParams.reldir = getDirName(pathParams, path.resolve(filePath))

		command = options.command.replace regEx.placeholder, (entire, placeholder)-> switch
			when placeholder is 'path' then filePath
			when pathParams[placeholder]? then pathParams[placeholder]
			else entire
		
		if options.forceColor and process.platform isnt 'win32'
			command = "FORCE_COLOR=true #{command}"

		exec command, (err, stdout, stderr)->
			if isValidOutput(stdout) then finalLogs.log[filePath] = stdout

			if isValidOutput(stderr) and not isValidOutput(err)
				finalLogs.log[filePath] = stderr
			else if isValidOutput(err)
				finalLogs.error[filePath] = stderr or err

			if isValidOutput(err) then reject() else resolve()













	## ==========================================================================
	## Helpers
	## ========================================================================== 
	getDirName = (pathParams, filePath)->
		dirInGlob = options.glob.match(/^[^\*\/]*/)[0]
		dirInGlob += if dirInGlob then '/' else ''
		filePath
			.replace pathParams.base, ''
			.replace process.cwd()+"/#{dirInGlob}", ''
			.slice(0, -1)

	isValidOutput = (output)->
		output and
		output isnt 'null' and
		(
			(typeof output is 'string' and output.length >= 1) or
			(typeof output is 'object')
		)

	formatOutputMessage = (message)->
		if options.trim
			message.slice(0, options.trim)
		else
			message






	outputFinalLogs = ()-> if Object.keys(finalLogs.log).length or Object.keys(finalLogs.error).length
		process.stdout.write '\n\n'
		for file,message of finalLogs.log
			console.log chalk.bgWhite.black.bold("Output")+' '+chalk.dim(file)
			console.log formatOutputMessage(message)
		
		for file,message of finalLogs.error
			console.log chalk.bgRed.white.bold("Error")+' '+chalk.dim(file)
			console.log formatOutputMessage(message)

		finish()






