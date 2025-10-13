#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.sysadmintools.garage_s3 as garage_s3_installer

mut garage_s3 := garage_s3_installer.get()!
garage_s3.install()!
garage_s3.start()!
garage_s3.destroy()!
