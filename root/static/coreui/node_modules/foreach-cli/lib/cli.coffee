yargs = require('yargs')
yargs
	.usage(require('./cliUsage').usage)
	.options(require './cliOptions')
	.epilogue(require('./cliUsage').epilogue)
	.wrap(yargs.terminalWidth())
	.help('h')
	.version(()-> require('../package.json').version)
args = yargs.argv
requiresHelp = args.h or args.help
suppliedOptions =
	'glob': args.g or args.glob or args._[0]
	'command': args.x or args.execute or args._[1]
	'ignore': args.i or args.ignore
	'nodir': args.nd or args.nodir
	'trim': args.t or args.trim
	'forceColor': args.c or args.forceColor
	'concurrent': args.C or args.concurrent

if requiresHelp or not suppliedOptions.glob or not suppliedOptions.command
	process.stdout.write(yargs.help());
	process.exit(0)


require('./foreach')(suppliedOptions)