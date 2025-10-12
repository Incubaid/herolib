#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.db.postgresql as postgresql_installer

mut db := postgresql_installer.get()!

db.install()!
db.start()!
db.destroy()!
