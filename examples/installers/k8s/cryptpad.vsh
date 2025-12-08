#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.k8_apps.biz.k8_cryptpad

// This example demonstrates how to use the CryptPad installer.

// 1. Create a new installer instance with custom configuration
mut installer := k8_cryptpad.get(
	name:   'demo'  // Short name to avoid TFGW 36-char limit
	create: true
)!

// 2. Configure custom paths (testing data parsing)
installer.cryptpad_path = '/tmp/cryptpad-demo/cryptpad.yaml'
installer.tfgw_cryptpad_path = '/tmp/cryptpad-demo/tfgw-cryptpad.yaml'
installer.config_js_path = '/tmp/cryptpad-demo/config.js'

// 3. Install CryptPad.
//    This will generate the necessary Kubernetes YAML files and apply them to your cluster.
installer.install()!

println('CryptPad installation completed!')
println('Custom paths used:')
println('  - Cryptpad YAML: ${installer.cryptpad_path}')
println('  - TFGW YAML: ${installer.tfgw_cryptpad_path}')
println('  - Config JS: ${installer.config_js_path}')

// 4. To destroy the deployment, you can run the following:
// installer.destroy()!
