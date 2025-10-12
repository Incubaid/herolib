#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.db.zerodb as zerodb_installer

mut db := zerodb_installer.get()!

db.install()!
db.start()!
db.destroy()!
