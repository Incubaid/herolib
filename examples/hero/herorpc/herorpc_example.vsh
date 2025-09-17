#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels.rpc

// when httpport is set, the rpc will be available over http
// if 0, then its only available on unix socket /tmp/heromodels
mut http_port := 9933

if http_port == 0 {
	println('
    #to test the discover function:
    echo \'\{"jsonrpc":"2.0","method":"rpc.discover","params":[],"id":1\}\' \\
      | nc -U /tmp/heromodels
    \'
    #to test interactively:

    nc -U /tmp/heromodels

    then e.g. do

    \{"jsonrpc":"2.0","method":"comment_set","params":{"comment":"Hello world!","parent":0,"author":42},"id":1\}

    needs to be on one line for openrpc to work

    ')
} else {
	println('
    #to test the discover function:
	curl -X POST -H "Content-Type: application/json" -d \'\{"jsonrpc":"2.0","method":"rpc.discover","id":1,"params":[]\}\' http://localhost:9933/
    \'
	')
}

rpc.start(http_port: http_port)!
