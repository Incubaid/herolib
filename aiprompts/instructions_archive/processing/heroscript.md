## INTENT

we use heroscript to communicate actions and events in a structured format.
we want you to parse user intents and generate the corresponding heroscript.

ONLY RETURN THE HEROSCRIPT STATEMENTS, can be more than 1

## HEROSCRIPT FORMAT

HeroScript is a concise scripting language with the following structure:

```heroscript
!!actor.action_name
	param1: 'value1'
	param2: 'value with spaces'
	multiline_description: '
		This is a multiline description.
		It can span multiple lines.
		'
	arg1 arg2 // Arguments without keys

!!actor.action_name2 param1:something param2:'something with spaces' nr:3
```

Key characteristics:

- **Actions**: Start with `!!`, followed by `actor.action_name` (e.g., `!!mailclient.configure`).
- **Parameters**: Defined as `key:value`. Values can be quoted for spaces.
- **Multiline Support**: Parameters like `description` can span multiple lines.
- **Arguments**: Values without keys (e.g., `arg1`).
- params can be on 1 line, with spaces in between
- time can be as +1h, +1d, +1w (hour, day, week), ofcourse 1 can be any number, +1 means 1 hour from now
- time format is:  dd/mm/yyyy hh:mm (ONLY USE THIS)
- comma separation is used a lot in arguments e.g. 'jan,kristof' or 'jan , kristof' remove spaces, is list of 2
- note only !! is at start of line, rest has spaces per instruction
- make one empty line between 1 heroscript statements
- everything after // is comment

## HEROSCRIPT SCHEMA

the language we understand

### calendar management

```heroscript 
!!calendar.create when:'+1h'  descr:'this is event to discuss eng' attendees:'jan,kristof' name:'meet1' tags:'eng,urgent'
!!calendar.delete name:'meet1'
!!calendar.list tags:'urgent'

```

### contact management

```heroscript 
!!contact.add name:'jan' email:'jan@example.com' phone:'123-456-7890'
!!contact.remove name:'jan'
!!contact.list

```

### task management

```heroscript 
!!task.create title:'Prepare presentation' due:'+1d' assignee:'jan' name:'task1'  tags:'eng,urgent'
	deadline:'+10d' duration:'1h'
!!task.update name:'task1' status:'in progress'
!!task.delete name:'task1'
!!task.list

```

### project management

```heroscript 
!!project.create title:'Cloud Product Development' description:'Track progress of cloud product development' name:'cloud_prod'
!!project.update name:'cloud_prod' status:'in progress'
!!project.delete name:'cloud_prod'
!!project.list
!!project.tasks_list name:'cloud_prod' //required properties are name, description, and assignee of not given ask
!!project.tasks_add names:'task1, task2'
!!project.tasks_remove names:'task1, task2'

```

### SUPPORTED TAGS

only tags supported are: 

- for intent: eng, prod, support, mgmt, marketing
- for urgency: urgent, high, medium, low

### generic remarks

- names are lowercase and snake_case, can be distilled out of title if only title given, often a user will say name but that means title
- time: format of returned data or time is always dd/mm/yyyy hh:min

## IMPORTANT STARTING INFO

- current time is  10/08/2025 05:10 , use this to define any time-related parameters

## USER INTENT

I want a meeting tomorrow 10am, where we will discuss our new product for the cloud with jan and alex, and the urgency is high

also let me know which other meetings I have which are urgent

can you make a project where we can track the progress of our new product development? Name is 'Cloud Product Development'

Please add tasks to the project in line to creating specifications, design documents, and implementation plans.