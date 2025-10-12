#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.lang.vlang
import incubaid.herolib.installers.sysadmintools.daguserver
import incubaid.herolib.installers.sysadmintools.b2 as b2_installer

vlang.v_analyzer_install()!
daguserver.new()! // will install & start a daguserver
