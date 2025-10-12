#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.sysadmintools.actrunner
// import incubaid.herolib.installers.virt.herocontainers

mut actrunner_ := actrunner.get()!
actrunner_.install()!
// herocontainers.start()!
