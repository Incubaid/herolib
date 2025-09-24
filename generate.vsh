#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import os
import flag
import freeflowuniverse.herolib.core.generator.installer_client as generator

mut fp := flag.new_flag_parser(os.args)
fp.application('generate.vsh')
fp.version('v0.1.0')
fp.description('Generate code')
fp.skip_executable()

mut path := fp.string('path', `p`, '', 'Path where to generate a module, if not mentioned will scan over all installers & clients.\nif . then will be path we are on.')
reset := fp.bool('reset', `r`, false, 'If we want to reset')
interactive := fp.bool('interactive', `i`, false, 'If we want to work interactive')
scan := fp.bool('scan', `s`, false, 'If we want to scan')
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

if additional_args.len > 0 {
	eprintln('Unexpected arguments: ${additional_args.join(' ')}')
	println(fp.usage())
	exit(1)
}

// reset               bool     // regenerate all, dangerous !!!
// interactive         bool 	 //if we want to ask
// path                string

if path.trim_space() == '.' {
	path = os.getwd()
}

if !scan {
	generator.do(path: path, reset: reset, interactive: interactive)!
} else {
	generator.scan(path: path, reset: reset, interactive: interactive)!
}
