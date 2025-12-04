#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.sysadmintools.actrunner

mut actrunner_ := actrunner.get()!
actrunner_.install()!
actrunner_.destroy()!
