in hero.db

make a generic function which takes any of the root objects (which inherits from Base)

and gets a json from it and add a save() function to it to store it in postgresql (see postgresql client)
and also a get and deserializes

the json is put in table as follows

tablename: $dirname_$rootobjectname all lowercase

each table has

- id
- ... the fields which represents indexes (see @[index])
- data which is the json

information how to use generics see aiprompts/v_advanced/generics.md and aiprompts/v_advanced/reflection.md