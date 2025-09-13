#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels

mut mydb := heromodels.new()!

mut o := mydb.comments.new(comment: 'Hello, world!')!

o.tags = mydb.comments.db.tags_get(['tag1', 'tag2'])!

oid := mydb.comments.set(o)!
mut o2 := mydb.comments.get(oid)!

println(oid)
println(o2)

mut objects := mydb.comments.list()!
println(objects)
