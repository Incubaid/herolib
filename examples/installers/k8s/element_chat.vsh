#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.k8_apps.communication.k8_element_chat

// This example demonstrates how to use the Element Chat installer.

// 1. Create a new installer instance with specific hostnames.
//    Replace 'matrixchattest' and 'elementchattest' with your desired hostnames.
//    Note: Use only alphanumeric characters (no underscores or dashes).
mut installer := k8_element_chat.get(
	name:   'demo'
	create: true
)!

// k8_element_chat.delete()!

// 2. Configure the installer (all settings are optional with sensible defaults)
// installer.matrix_hostname = 'matrixchattest'
// installer.element_hostname = 'elementchattest'
// installer.namespace = 'chat'

// // Conduit (Matrix homeserver) configuration
// installer.conduit_port = 6167 // Default: 6167
// installer.database_backend = 'rocksdb' // Default: 'rocksdb' (can be 'sqlite')
// installer.database_path = '/var/lib/matrix-conduit' // Default: '/var/lib/matrix-conduit'
// installer.allow_registration = true // Default: true
// installer.allow_federation = true // Default: true
// installer.log_level = 'info' // Default: 'info' (can be 'debug', 'warn', 'error')

// // Element web client configuration
// installer.element_brand = 'Element' // Default: 'Element'

// 3. Install Element Chat.
//    This will generate the necessary Kubernetes YAML files and apply them to your cluster.
installer.install()!

// println('Element Chat installation started.')
// println('Matrix homeserver will be available at: https://${installer.matrix_hostname}.gent01.grid.tf')
// println('Element web client will be available at: https://${installer.element_hostname}.gent01.grid.tf')

// 4. To destroy the deployment, you can run the following:
// installer.destroy()!
