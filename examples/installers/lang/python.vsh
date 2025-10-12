#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.lang.python as python_module

mut python_installer := python_module.get()!
python_installer.install()!

// python_installer.destroy()!
