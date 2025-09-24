#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import flag

mut fp := flag.new_flag_parser(os.args)
fp.application('compile.vsh')
fp.version('v0.1.0')
fp.description('Compile hero binary in debug or production mode')
fp.skip_executable()

prod_mode := fp.bool('prod', `p`, false, 'Build production version (optimized)')
help_requested := fp.bool('help', `h`, false, 'Show help message')

if help_requested {
	println(fp.usage())
	exit(0)
}

additional_args := fp.finalize() or {
	eprintln(err)
	println(fp.usage())
	exit(1)
}
