#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.base
import incubaid.herolib.develop.gittools

pub struct MyClass {
	base.Base
pub mut:
	descr string
}

// will fetch default context
mut c := base.context()!

mut s := c.session_new()!
println(s)

mut gs := gittools.configure(multibranch: true, root: '/tmp/code', name: 'test')!
// mut gs:=gittools.get(name:"test")!

mut s2 := c.session_latest()!
println(s2)

println(gs)

mut mc := MyClass{
	type_name: 'mytype'
	instance:  'first'
}

mut mysession := mc.session()!

println(mc)
println(mysession)
