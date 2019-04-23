fs = require 'fs-extra'
fs.createOutputStream = require 'create-output-stream'
lcovParse = require 'lcov-parse'
request = require 'request'
svg2png = require 'svg2png'


genBadgeUrl = (label, value, color)->
	"https://img.shields.io/badge/#{encodeURIComponent(label)}-#{encodeURIComponent(value)}-#{color}.svg"


## ==========================================================================
## Coverage
## ========================================================================== 
calcCoverage = (lcov)->
	percentages =
		'functions': lcov.functions.hit / lcov.functions.found
		'lines': lcov.lines.hit / lcov.lines.found
	average = (percentages.functions + percentages.lines) / 2
	coverage = (average*100).toString().split('.')[0]+'%'
	percent = parseFloat(coverage)
	color = switch
		when percent is 100 then 'brightgreen'
		when percent > 97 then 'green'
		when percent > 93 then 'yellowgreen'
		when percent > 90 then 'yellow'
		when percent > 85 then 'orange'
		else 'red'
	
	{coverage, color}


downloadBadge = (name)->
	lcovDirPath = "test/coverage/#{name}"
	destPath = ".config/badges/coverage-#{name}"
	
	fs.ensureDir lcovDirPath, ()->
		lcovParse "#{lcovDirPath}/lcov.info", (err, parsed)-> if err then console.warn(err) else
			values = calcCoverage(parsed[0])
			
			request genBadgeUrl("coverage (#{name})", values.coverage, values.color)
				.pipe fs.createOutputStream("#{destPath}.svg")
				
				.on 'finish', (err)-> if err then console.error(err) else
					fs.readFile "#{destPath}.svg", (err, svgBuffer)-> if err then console.error(err) else
						svg2png(svgBuffer).then (pngBuffer)->
							fs.outputFile "#{destPath}.png", pngBuffer


downloadBadge('node')









