#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.k8s.gitea

// This example demonstrates how to use the Gitea installer.

// 1. Create a new installer instance with a specific hostname.
//    Replace 'mygitea' with your desired hostname.
//    Note: Use only alphanumeric characters (no underscores or dashes).
mut installer := gitea.get(
	name:   'kristof'
	create: true
)!

// 2. Configure the installer (all settings are optional with sensible defaults)
// installer.hostname = 'giteaapp'           // Default: 'giteaapp'
// installer.namespace = 'forge'             // Default: 'forge'

// // Gitea server configuration
// installer.http_port = 3000                // Default: 3000
// installer.disable_registration = false    // Default: false (allow new user registration)
// installer.db_type = 'sqlite3'             // Default: 'sqlite3' (can be 'postgres', 'mysql')
// installer.db_path = '/data/gitea/gitea.db' // Default: '/data/gitea/gitea.db'
// installer.storage_size = '5Gi'            // Default: '5Gi' (PVC storage size)

// 3. Install Gitea.
//    This will generate the necessary Kubernetes YAML files and apply them to your cluster.
installer.install()!

// println('Gitea installation started.')
// println('You can access it at: https://${installer.hostname}.gent01.grid.tf')

// 4. To destroy the deployment, you can run the following:
// installer.destroy()!
