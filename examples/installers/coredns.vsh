#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.infra.coredns as coredns_installer
import incubaid.herolib.osal

// coredns_installer.delete()!
mut installer := coredns_installer.get()!
installer.build()!
