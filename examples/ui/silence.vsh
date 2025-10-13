#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.osal
import incubaid.herolib.ui.console

console.silent_set()
mut job2 := osal.exec(cmd: 'ls /', debug: true)!
println('I got nothing above')

console.silent_unset()
println('now I will get output')

osal.exec(cmd: 'ls /', debug: true)!
