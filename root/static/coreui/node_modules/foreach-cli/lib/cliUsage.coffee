chalk = require 'chalk'

labels = 
	'or': 				" #{chalk.bold.bgWhite.black 'OR'} "
	'usage': 			chalk.bgYellow.black('Usage')
	'placeholders': 	chalk.bgGreen.black('Placeholders')
	'example': 			chalk.bgCyan.black('Examples')
	'glob': 			chalk.italic.dim('<glob>')
	'command': 			chalk.italic.dim('<command>')
	'options': 			'-[c|t|C]'

values = 
	'usage': "foreach-cli -g #{labels.glob} -x #{labels.command} #{labels.options} #{labels.or} #{labels.glob} #{labels.command} #{labels.options}"
	'placeholders': [
		chalk.dim 'All placeholders can be denoted either with {{placeholder}} or #{placeholder}'
		"path    -  full path and filename"
		"root    -  file root"
		"dir     -  path without the filename"
		"reldir  -  directory name of file relative to the glob provided"
		"base    -  file name and extension"
		"ext     -  just file extension"
		"name    -  just file name"
	].join '\n  '
	'example': [
		"foreach -g 'assets/*.scss' -x 'node-sass {{path}} -o dist/css/{{name}}.css'"
		"forEach 'files/*' 'mv {{path}} newDir/{{base}}'"
		"foreach-cli -g './**' -x 'stat -x \#{base} >> ./file-stats.log'"
	].map((str)-> chalk.dim(str)).join '\n  '


module.exports =
	usage: "#{labels.usage} #{values.usage}"
	epilogue: '\n\n'+[
		"#{labels.placeholders} #{values.placeholders}"
		"#{labels.example}\n  #{values.example}"
	].join '\n\n\n'