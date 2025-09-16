#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused run

import freeflowuniverse.herolib.core.redisclient
import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!
mydb.comments.db.redis.flushdb()!

mut o := mydb.comments.new(comment: 'Hello, world!')!

o.tags = mydb.comments.db.tags_get(['tag1', 'tag2'])!

mydb.comments.set(o)!
mut o2 := mydb.comments.get(o.id)!

println('Comment ID: ${o.id}')
println('Comment object: ${o2}')

// mut objects := mydb.comments.list()!
// println(objects)
