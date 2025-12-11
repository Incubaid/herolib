#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.k8_apps.communication.stalwart

// This example demonstrates how to use the Stalwart Mail Server installer.

// 1. Create a new installer instance with custom settings
mut installer := stalwart.get(
	name:   'demo'  // Short name to avoid TFGW 36-char limit
	create: true
)!

// 2. Configure custom settings (optional - all have sensible defaults)
// installer.hostname = 'mymail'  // Custom hostname for TFGW
// installer.admin_user = 'admin'
// installer.admin_password = 'mysecurepassword'
// installer.storage_size = '50Gi'
// installer.log_level = 'debug'

// 3. Install Stalwart Mail Server
//    This will deploy:
//    - TFGW for HTTPS access to web UI/JMAP/CalDAV/CardDAV
//    - Stalwart deployment with ConfigMap and PVC
//    - LoadBalancer service for mail ports (SMTP/IMAP/POP3/Sieve)
installer.install()!

println('Stalwart Mail Server installation completed!')
println('Configuration:')
println('  - Hostname: ${installer.hostname}')
println('  - Admin User: ${installer.admin_user}')
println('  - Storage Size: ${installer.storage_size}')
println('  - Log Level: ${installer.log_level}')

// 4. To destroy the deployment:
// installer.destroy()!
