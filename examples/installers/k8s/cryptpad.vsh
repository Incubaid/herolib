#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.k8s.cryptpad

// This example demonstrates how to use the CryptPad installer.

// 1. Create a new installer instance with a specific hostname.
//    Replace 'mycryptpad' with your desired hostname.
mut installer := cryptpad.get(
	name:   'kristof'
	create: true
)!

// 2. Install CryptPad.
//    This will generate the necessary Kubernetes YAML files and apply them to your cluster.
// installer.install()!
// cryptpad.delete()!

// println('CryptPad installation started.')
// println('You can access it at https://${installer.hostname}.gent01.grid.tf')

// 3. To destroy the deployment, you can run the following:
installer.destroy()!
