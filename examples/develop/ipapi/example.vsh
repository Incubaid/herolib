#!/usr/bin/env -S v -n -w -gc none -no-retry-compilation -d use_openssl -enable-globals run

import incubaid.herolib.clients.ipapi
import os

mut ip_api_client := ipapi.get()!
info := ip_api_client.get_ip_info('37.27.132.46')!
println('info: ${info}')
