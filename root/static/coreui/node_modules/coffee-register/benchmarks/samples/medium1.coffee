song = ["do", "re", "mi", "fa", "so"]

singers = {Jagger: "Rock", Elvis: "Roll"}

bitlist = [
  1, 0, 1
  0, 0, 1
  1, 1, 0
]

kids =
  brother:
    name: "Max"
    age:  11
  sister:
    name: "Ida"
    age:  9



gold = silver = rest = "unknown"

awardMedals = (first, second, others...) ->
  gold   = first
  silver = second
  rest   = others

contenders = [
  "Michael Phelps"
  "Liu Xiang"
  "Yao Ming"
  "Allyson Felix"
  "Shawn Johnson"
  "Roman Sebrle"
  "Guo Jingjing"
  "Tyson Gay"
  "Asafa Powell"
  "Usain Bolt"
]

awardMedals contenders...

a = "Gold: " + gold
b = "Silver: " + silver
c = "The Field: " + rest




eat = (args...)-> return args
menu = (args...)-> return args

# Eat lunch.
eat food for food in ['toast', 'cheese', 'wine']

# Fine five course dining.
courses = ['greens', 'caviar', 'truffles', 'roast', 'cake']
menu i + 1, dish for dish, i in courses

# Health conscious meal.
foods = ['broccoli', 'spinach', 'chocolate']
eat food for food in foods when food isnt 'chocolate'



class EventfulPromise extends require('events')
	constructor: (task)->
		super
		@init(task)
	
	init: (@task)->
		@taskPromise = Promise.resolve(if typeof @task is 'function' then @task.call(@) else @task)
		return @
	
	then: ()-> @taskPromise.then(arguments...)
	catch: ()-> @taskPromise.catch(arguments...)

module.exports = EventfulPromise



eat = (args...)-> return args
menu = (args...)-> return args

# Eat lunch.
eat food for food in ['toast', 'cheese', 'wine']

# Fine five course dining.
courses = ['greens', 'caviar', 'truffles', 'roast', 'cake']
menu i + 1, dish for dish, i in courses

# Health conscious meal.
foods = ['broccoli', 'spinach', 'chocolate']
eat food for food in foods when food isnt 'chocolate'



class EventfulPromise extends require('events')
	constructor: (task)->
		super
		@init(task)
	
	init: (@task)->
		@taskPromise = Promise.resolve(if typeof @task is 'function' then @task.call(@) else @task)
		return @
	
	then: ()-> @taskPromise.then(arguments...)
	catch: ()-> @taskPromise.catch(arguments...)

eat = (args...)-> return args
menu = (args...)-> return args

# Eat lunch.
eat food for food in ['toast', 'cheese', 'wine']

# Fine five course dining.
courses = ['greens', 'caviar', 'truffles', 'roast', 'cake']
menu i + 1, dish for dish, i in courses

# Health conscious meal.
foods = ['broccoli', 'spinach', 'chocolate']
eat food for food in foods when food isnt 'chocolate'



class EventfulPromise extends require('events')
	constructor: (task)->
		super
		@init(task)
	
	init: (@task)->
		@taskPromise = Promise.resolve(if typeof @task is 'function' then @task.call(@) else @task)
		return @
	
	then: ()-> @taskPromise.then(arguments...)
	catch: ()-> @taskPromise.catch(arguments...)

module.exports = EventfulPromise