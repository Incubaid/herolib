#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.k8_apps.devel.k8_gitea

// This example demonstrates how to use the Gitea installer with custom configuration.

// 1. Create a new installer instance with custom settings
mut installer := k8_gitea.get(
	name:   'demo'  // Short name to avoid TFGW 36-char limit
	create: true
)!

// 2. Configure custom settings (testing data parsing)
installer.http_port = 3001  // Custom port instead of default 3000
installer.disable_registration = true  // Disable new user registration
installer.storage_size = '10Gi'  // Custom storage size

// Database configuration - Using PostgreSQL
installer.db_type = 'postgres'
installer.db_host = 'postgres'
installer.db_name = 'gitea_demo'
installer.db_user = 'gitea_admin'
installer.db_password = 'secure_password_123'

// Custom YAML paths
installer.gitea_app_path = '/tmp/gitea-demo/gitea.yaml'
installer.tfgw_path = '/tmp/gitea-demo/tfgw-gitea.yaml'
installer.postgres_path = '/tmp/gitea-demo/postgres.yaml'

// 3. Install Gitea
installer.install()!

println('Gitea installation completed!')
println('Configuration:')
println('  - HTTP Port: ${installer.http_port}')
println('  - Registration: ${if installer.disable_registration { 'Disabled' } else { 'Enabled' }}')
println('  - Database: ${installer.db_type} (${installer.db_name})')
println('  - Storage: ${installer.storage_size}')
println('Custom paths:')
println('  - Gitea YAML: ${installer.gitea_app_path}')
println('  - TFGW YAML: ${installer.tfgw_path}')
println('  - Postgres YAML: ${installer.postgres_path}')

// 4. To destroy the deployment:
// installer.destroy()!
