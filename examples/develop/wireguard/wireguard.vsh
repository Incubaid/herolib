#!/usr/bin/env -S v -n -w -gc none -no-retry-compilation -d use_openssl -enable-globals run

import incubaid.herolib.clients.wireguard
import incubaid.herolib.installers.net.wireguard as wireguard_installer
import time
import os

mut wg_installer := wireguard_installer.get()!
wg_installer.install()!

// Create Wireguard client
mut wg := wireguard.get()!
config_file_path := '${os.dir(@FILE)}/wg0.conf'

wg.start(config_file_path: config_file_path)!
println('${config_file_path} is started')

time.sleep(time.second * 2)

info := wg.show()!
println('info: ${info}')

config := wg.show_config(interface_name: 'wg0')!
println('config: ${config}')

private_key := wg.generate_private_key()!
println('private_key: ${private_key}')

public_key := wg.get_public_key(private_key: private_key)!
println('public_key: ${public_key}')

wg.down(config_file_path: config_file_path)!
println('${config_file_path} is down')

wg_installer.destroy()!
