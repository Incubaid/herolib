#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.db.qdrant as qdrant_installer

mut db := qdrant_installer.get()!

db.install()!
db.start()!
db.destroy()!
