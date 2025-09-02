lets make an openrpc server
over unixsocker

on /tmp/heromodels

put code in lib/hero/heromodels/openrpc

do example for comment.v

make struct called RPCServer

put as methods

- comment_get(args CommentGetArgs)[]Comment!   //chose the params well is @[params] struct  CommentGetArgs always with id… in this case maybe author. … 
    - walk over the hset with data, find the one we are looking for based on the args
- comment_set(obj Comment)! 
- comment_delete(id…)
- comment_list() ![]u32
- discover()!string //returns a full openrpc spec

make one .v file per type of object now comment_…

we will then do for the other objects too

also generate the openrpc spec based on the methods we have and the objects we return


