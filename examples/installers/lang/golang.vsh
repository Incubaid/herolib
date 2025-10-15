#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.lang.golang

mut golang_installer := golang.get()!
golang_installer.install()!
