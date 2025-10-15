#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.infra.dify as dify_installer

mut dify := dify_installer.get()!

dify.install()!
dify.start()!
// dify.destroy()!
