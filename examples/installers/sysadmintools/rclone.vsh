#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.sysadmintools.rclone as rclone_installer

mut rclone := rclone_installer.get()!
rclone.install()!
rclone.destroy()!
