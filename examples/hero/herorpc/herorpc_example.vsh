#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.hero.heromodels.rpc

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

rpc.start()!
