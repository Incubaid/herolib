## INSTRUCTIONS

the user will send me multiple instructions what they wants to do, I want you to put them in separate categories

The categories we have defined are:

- calendar management
  - schedule meetings, events, reminders
  - list these events
  - delete them
- contact management
  - add/remove contact information e.g. phone numbers, email addresses, address information
  - list contacts, search
- task or project management
  - anything we need to do, anything we need to track and plan
  - create/update tasks, set deadlines
  - mark tasks as complete
  - delete tasks
  - project management
- communication (chat, email)
  - see what needs to be communicate e.g. send a chat to ... 
- search statements
  - find on internet, find specific information from my friends

I want you to detect the intent and make multiple blocks out of the intent, each block should correspond to one of the identified intents, identify the intent with name of the category eg. calendar, only use above names



what user wants to do, stay as close as possible to the original instructions, copy the exact instructions as where given by the user, we only need to sort the instructions in these blocks

for each instruction make a separate block, e.g. if 2 tasks are given, create 2 blocks

the format to return is: (note newline after each title of block)

```template
===CALENDAR===\n

$the copied text from what user wants

===CONTACT===\n
...

===QUESTION===\n

put here what our system needs to ask to the user anything which is not clear

===END===\n

```

I want you to execute above on instructions as given by user below, give text back ONLY supporting the template

note for format is only ===$NAME=== and then on next lines the original instructions from the user, don't change

## special processing of info

- if a date or time specified e.g. tomorrow, time, ... calculate back from current date

## IMPORTANT STARTING INFO

- current time is  10/08/2025 05:10  (format of returned data is always dd/mm/yyyy hh:min)
    - use the current time to define formatted time out of instructions
    - only return the formatted time

## UNCLEAR INFO

check in instructions e.g. things specified like you, me, ... 
are not clear ask specifically who do you mean

if task, specify per task, who needs to do it and when, make sure each instruction (block) is complete and clear for further processing

be very specific with the questions e.g. who is you, ...

## EXECUTE ABOVE ON THE FOLLOWING

I am planning a birthday for my daughters tomorrow, there will be 10 people.

I would like to know if you can help me with the preparations.

I need a place for my daughter's birthday party.

I need to send message to my wife isabelle that she needs to pick up the cake.