#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.k8_apps.biz.k8_nextcloud

// This example demonstrates how to use the Nextcloud installer with custom configuration.

// 1. Create a new installer instance with custom settings
mut installer := k8_nextcloud.get(
	name:   'dimo'  // Short name to avoid TFGW 36-char limit
	create: true
)!

// 2. Configure custom settings (testing data parsing)
installer.nextcloud_storage_size = '15Gi'  // Custom Nextcloud storage
installer.postgres_storage_size = '12Gi'   // Custom PostgreSQL storage

// Custom admin credentials
installer.admin_user = 'ncadmin'
installer.admin_password = 'CustomAdminPass123!'

// Custom database credentials
installer.db_user = 'nc_dbuser'
installer.db_password = 'CustomDbPass456!'

// Custom YAML paths
installer.secrets_path = '/tmp/nextcloud-demo/secrets.yaml'
installer.nextcloud_path = '/tmp/nextcloud-demo/nextcloud.yaml'
installer.postgres_path = '/tmp/nextcloud-demo/postgres.yaml'
installer.redis_path = '/tmp/nextcloud-demo/redis.yaml'
installer.tfgw_path = '/tmp/nextcloud-demo/tfgw.yaml'

// 3. Install Nextcloud
// Note: The actual FQDN will be dynamically fetched from TFGW status after deployment
installer.install()!

println('Nextcloud installation completed!')
println('Configuration:')
println('  - Nextcloud Storage: ${installer.nextcloud_storage_size}')
println('  - PostgreSQL Storage: ${installer.postgres_storage_size}')
println('  - Admin User: ${installer.admin_user}')
println('  - Database: ${installer.db_name} (user: ${installer.db_user})')
println('Custom paths:')
println('  - Nextcloud YAML: ${installer.nextcloud_path}')
println('  - PostgreSQL YAML: ${installer.postgres_path}')
println('  - Redis YAML: ${installer.redis_path}')
println('  - TFGW YAML: ${installer.tfgw_path}')

// 4. To destroy the deployment:
// installer.destroy()!
