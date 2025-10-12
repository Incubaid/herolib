#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.db.meilisearch_installer

mut meilisearch := meilisearch_installer.get()!
meilisearch.install()!
meilisearch.start()!
meilisearch.destroy()!
