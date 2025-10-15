#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.lang.nodejs

mut nodejs_installer := nodejs.get()!
// nodejs_installer.install()!
nodejs_installer.destroy()!
