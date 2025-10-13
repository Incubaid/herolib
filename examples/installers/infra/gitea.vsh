#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.infra.gitea as gitea_installer

mut gitea := gitea_installer.get()!
gitea.install()!
gitea.start()!
gitea.destroy()!
