distill vlang objects out of the calendr/contact/circle and create the missing parts

organze per root object which are @[heap] and in separate file with name.v

the rootobjects are

- user
- group (which users are members and in which role can be admin, writer, reader, can be linked to subgroups)
- calendar (references to event, group)
- calendar_event (everything related to an event on calendar, link to one or more fs_file)
- project  (grouping per project, defines swimlanes and milestones this allows us to visualize as kanban, link to group, link to one or more fs_file )
- project_issue (and issue is specific type, e.g. task, story, bug, question,…), issue is linked to project by id, also defined priority…, on which swimlane, deadline, assignees, … ,,,, has tags, link to one or more fs_file
- chat_group (link to group, name/description/tags)
- chat_message (link to chat_group, link to parent_chat_messages and what type of link e.g. reply or reference or? , status, … link to one or more fs_file)
- fs = filesystem (link to group)
- fs_dir = directory in filesystem, link to parent, link to group
- fs_file (link to one or more fs_dir, list of references to blobs as blake192)
- fs_symlink  (can be link to dir or file)
- fs_blob (the data itself, max size 1 MB, binary data, id = blake192)

the group’s define how people can interact with the parts e.g. calendar linked to group, so readers of that group can read and have copy of the info linked to that group

all the objects are identified by their blake192 (based on the content)

there is a special table which has link between blake192 and their previous & next version, so we can always walk the three, both parts are indexed (this is independent of type of object)






