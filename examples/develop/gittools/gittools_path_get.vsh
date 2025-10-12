#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.develop.gittools
import incubaid.herolib.osal
import time

mut gs := gittools.new()!
mydocs_path := gs.get_path(
	pull:  true
	reset: false
	url:   'https://git.threefold.info/tfgrid/info_docs_depin/src/branch/main/docs'
)!

println(mydocs_path)
