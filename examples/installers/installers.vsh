#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.lang.rust
import incubaid.herolib.installers.lang.python
import incubaid.herolib.installers.lang.nodejs
import incubaid.herolib.installers.lang.golang
import incubaid.herolib.core

core.interactive_set()! // make sure the sudo works so we can do things even if it requires those rights

mut i1 := golang.get()!
i1.install()!
