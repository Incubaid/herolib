#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.generator.generic as generator
import incubaid.herolib.core.pathlib

// mut args := generator.GeneratorArgs{
// 	path:  '~/code/github/incubaid/herolib/lib/clients'
// 	force: true
// }

mut args2 := generator.GeneratorArgs{
	path:  '~/code/github/incubaid/herolib/lib/develop/heroprompt'
	force: true
}
generator.scan(args2)!

// mut args := generator.GeneratorArgs{
// 	path:  '~/code/github/incubaid/herolib/lib/installers'
// 	force: true
// }

// generator.scan(args)!
