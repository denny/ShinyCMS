PATH = require 'path'
execa = require 'execa'
fs = require 'fs-extra'
chai = require 'chai'
expect = chai.expect
should = chai.should()
bin = PATH.resolve 'bin'


suite "ForEach-cli", ()->
	suiteSetup (done)-> fs.ensureDir 'test/temp', done
	suiteTeardown (done)-> fs.remove 'test/temp', done
	
	test "Will execute a given command on all matched files/dirs in a given glob when using explicit arguments", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '-x', 'echo {{base}} >> test/temp/one']).then (err)->
			result = fs.readFileSync 'test/temp/one', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 3
			expect(resultLines[0]).to.equal 'foldr.css'
			expect(resultLines[1]).to.equal 'main.copy.css'
			expect(resultLines[2]).to.equal 'main.css'
		

	
	test "Will execute a given command on all matched files/dirs in a given glob when using positional arguments", ()->
		execa(bin, ['test/samples/sass/css/*', 'echo {{base}} >> test/temp/two']).then (err)->
			result = fs.readFileSync 'test/temp/two', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 3
			expect(resultLines[0]).to.equal 'foldr.css'
			expect(resultLines[1]).to.equal 'main.copy.css'
			expect(resultLines[2]).to.equal 'main.css'
	


	test "Placeholders can be used in the command which will be dynamically filled according to the subject path", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '-x', 'echo "{{name}} {{ext}} {{base}} {{reldir}} {{path}} {{dir}}" >> test/temp/three']).then (err)->
			result = fs.readFileSync 'test/temp/three', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 3
			expect(resultLines[0]).to.equal "foldr .css foldr.css samples/sass/css test/samples/sass/css/foldr.css #{process.cwd()}/test/samples/sass/css"
			expect(resultLines[1]).to.equal "main.copy .css main.copy.css samples/sass/css test/samples/sass/css/main.copy.css #{process.cwd()}/test/samples/sass/css"
			expect(resultLines[2]).to.equal "main .css main.css samples/sass/css test/samples/sass/css/main.css #{process.cwd()}/test/samples/sass/css"
	


	test "Placeholders can be denoted either with dual curly braces or a hash + single curly brace wrap", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '-x', 'echo "#{name} #{ext} #{base} #{reldir} #{path} #{dir}" >> test/temp/four']).then (err)->
			result = fs.readFileSync 'test/temp/four', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 3
			expect(resultLines[0]).to.equal "foldr .css foldr.css samples/sass/css test/samples/sass/css/foldr.css #{process.cwd()}/test/samples/sass/css"
			expect(resultLines[1]).to.equal "main.copy .css main.copy.css samples/sass/css test/samples/sass/css/main.copy.css #{process.cwd()}/test/samples/sass/css"
			expect(resultLines[2]).to.equal "main .css main.css samples/sass/css test/samples/sass/css/main.css #{process.cwd()}/test/samples/sass/css"



	test "Will execute a given command on all matched files/dirs in a given glob with ignore option", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '-i', '**/*copy*', '-x', 'echo {{base}} >> test/temp/five']).then (err)->
			result = fs.readFileSync 'test/temp/five', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines[0]).to.equal 'foldr.css'
			expect(resultLines[1]).to.equal 'main.css'



	test "Will execute a given command on all matched files in a given glob but ignoring the folders", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '--nodir', 'true', '-x', 'echo {{base}} >> test/temp/six']).then (err)->
			result = fs.readFileSync 'test/temp/six', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines[0]).to.equal 'main.copy.css'
			expect(resultLines[1]).to.equal 'main.css'



	test "Will execute a given command on all matched `.css` files in a given glob with ** but ignoring the folders", ()->
		execa(bin, ['-g', 'test/samples/sass/css/**/*.css', '--nodir', 'true', '-x', 'echo {{base}} >> test/temp/seven']).then (err)->
			result = fs.readFileSync 'test/temp/seven', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 3
			expect(resultLines[0]).to.equal 'sub.css'
			expect(resultLines[1]).to.equal 'main.copy.css'
			expect(resultLines[2]).to.equal 'main.css'









