#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.lang.rust as rust_module

mut rust_installer := rust_module.get()!
// rust_installer.install()!
rust_installer.destroy()!
