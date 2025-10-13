#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.base
import time

struct Person {
mut:
	name     string
	age      int = 20
	birthday time.Time
}

mut person := Person{
	name:     'Bob'
	birthday: time.now()
}
heroscript := encoderhero.encode[Person](person)!

println(heroscript)

person2 := encoderhero.decode[Person](heroscript)!
println(person2)

// show that it doesn't matter which action & method is used
heroscript2 := "!!a.b name:Bob age:20 birthday:'2025-02-06 09:57:30'"
person3 := encoderhero.decode[Person](heroscript)!

println(person3)
