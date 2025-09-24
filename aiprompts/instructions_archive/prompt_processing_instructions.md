We have our own instruction language called heroscript, below you will find details how to use it.

## heroscript


Heroscript is our small scripting language which is used for communicating with our digital tools like calendar management.

which has following structure

```heroscript

!!calendar.event_add
	title: 'go to dentist'
	start: '2025/03/01'
	description: '
		a description can be multiline

		like this
		'

!!calendar.event_delete
    title: 'go to dentist'

```

- the format is !!$actor.$action   (there is no space before !!)
- every parameter comes on next line with spaces in front (4 spaces, always use 4 spaces, dont make variation)
- every actor.action starts with !!
	- the first part is the actor e.g. calendar in this case
	- the 2e part is the action name
- multilines are supported see the description field

below you will find the instructions for different actors, comments how to use it are behind # which means not part of the the definition itself

## remarks on parameters used

- date
  - format of the date is yyyy/mm/dd hh:mm:ss
  - +1h means 1 hour later than now
  - +1m means 1 min later than now
  - +1d means 1 day later than now
  - same for -1h, -1m, -1d
- money expressed as 
  - $val $cursymbol
  - $cursymbol is 3 letters e.g. USD, capital
- lists are comma separated and '...' around


## generic instructions

- do not add information if not specifically asked for


## circle

every actor action happens in a circle, a user can ask to switch circles, command available is

```
!!circle.switch
	name: 'project x'

```

## calendar

```heroscript

!!calendar.event_add
	title: 'go to dentist'	
    start: '2025/03/01'
	end: '+1h'  #if + notation used is later than the start
	description: '
		a description can be multiline

		like this
		'
	attendees: 'tim, rob'

!!calendar.event_delete
    title: 'go to dentist'

```

## NOW DO ONE

schedule event tomorrow 10 am, for 1h, with tim & rob, we want to product management threefold
now is friday jan 17

only give me the instructions needed, only return the heroscript no text around

if not clear enough ask the user for more info

if not sure do not invent, only give instructions as really asked for
