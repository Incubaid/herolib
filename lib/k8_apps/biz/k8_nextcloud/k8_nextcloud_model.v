module k8_nextcloud

import incubaid.herolib.ui.console
import incubaid.herolib.data.encoderhero
import incubaid.herolib.virt.kubernetes
import incubaid.herolib.core.pathlib
import incubaid.herolib.k8_apps.core
import strings
import crypto.rand

pub const version = '0.0.0'
const singleton = false
const default = false

struct ConfigValues {
pub mut:
	hostname                string
	backends                string
	namespace               string
	nextcloud_storage_size  string
	postgres_storage_size   string
	admin_user              string
	admin_password          string
	db_name                 string
	db_user                 string
	db_password             string
	postgres_host           string
	redis_host              string
	fqdn                    string
}

@[heap]
pub struct NextcloudK8SInstaller {
pub mut:
	name string = 'nextcloud'
	
	// K8s integration
	k8app ?core.K8App
	
	// Storage configuration
	nextcloud_storage_size string = '10Gi'
	postgres_storage_size  string = '10Gi'
	
	// Admin credentials
	admin_user     string = 'admin'
	admin_password string  // Auto-generated if empty
	
	// Database configuration
	db_name     string = 'nextcloud'
	db_user     string = 'ncuser'
	db_password string  // Auto-generated if empty
	
	// Redis (no auth by default)
	redis_host string = 'nextcloud-redis'
	
	// YAML output paths
	secrets_path   string = '/tmp/nextcloud/secrets.yaml'
	postgres_path  string = '/tmp/nextcloud/postgres.yaml'
	redis_path     string = '/tmp/nextcloud/redis.yaml'
	tfgw_path      string = '/tmp/nextcloud/tfgw.yaml'
	nextcloud_path string = '/tmp/nextcloud/nextcloud.yaml'
	
	// Internal
	kube_client kubernetes.KubeClient @[skip]
}

// Generate a secure random password
fn generate_password() string {
	bytes := rand.bytes(24) or { return 'changeme' }
	return bytes.hex()
}

// your checking & initialization code if needed
fn obj_init(mycfg_ NextcloudK8SInstaller) !NextcloudK8SInstaller {
	mut mycfg := mycfg_
	
	if mycfg.name == '' {
		mycfg.name = 'nextcloud'
	}
	
	// Replace dashes, dots, and underscores with nothing in name
	mycfg.name = mycfg.name.replace('_', '')
	mycfg.name = mycfg.name.replace('-', '')
	mycfg.name = mycfg.name.replace('.', '')
	
	// Initialize k8app
	namespace := '${mycfg.name}-nextcloud-namespace'
	mycfg.k8app = core.k8app(
		app_name: 'nextcloud'
		app_instance: mycfg.name
		namespace: namespace
	)!
	
	// Auto-generate passwords if not provided
	if mycfg.admin_password == '' {
		mycfg.admin_password = generate_password()
		console.print_info('Generated admin password: ${mycfg.admin_password}')
	}
	
	if mycfg.db_password == '' {
		mycfg.db_password = generate_password()
		console.print_info('Generated database password: ${mycfg.db_password}')
	}
	
	mycfg.kube_client = kubernetes.get(create: true)!
	k8app := mycfg.k8app or { return error('k8app not initialized') }
	mycfg.kube_client.config.namespace = k8app.namespace
	
	return mycfg
}

// Generate TFGW YAML only (first step - before we know the FQDN)
fn configure_tfgw() ! {
	mut installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client
	
	master_ips := core.get_master_node_ips(mut k8s)!
	console.print_info('Master node IPs: ${master_ips}')
	
	mut backends_str_builder := strings.new_builder(100)
	for ip in master_ips {
		backends_str_builder.writeln('    - "http://[${ip}]:80"')
	}
	
	console.print_info('Generating TFGW configuration file...')
	
	// Create config_values for TFGW template only
	mut config_values := ConfigValues{
		hostname:  k8app.hostname
		backends:  backends_str_builder.str()
		namespace: k8app.namespace
	}
	
	// Ensure output directory exists
	mut tfgw_path_obj := pathlib.get(installer.tfgw_path)
	output_dir := tfgw_path_obj.path_dir()
	_ := pathlib.get_dir(path: output_dir, create: true)!
	
	// Generate TFGW YAML
	tfgw_yaml := $tmpl('./templates/tfgw.yaml')
	mut tfgw_path := pathlib.get_file(
		path:   installer.tfgw_path
		create: true
		check:  true
	)!
	tfgw_path.write(tfgw_yaml)!
	console.print_info('TFGW configuration file generated.')
}

// Generate remaining YAML files using the actual FQDN from TFGW
fn configure_with_fqdn(fqdn string) ! {
	mut installer := get()!
	k8app := installer.k8app or { return error('k8app not initialized') }
	
	console.print_info('Generating configuration files with FQDN: ${fqdn}...')
	
	// Create config_values for template generation with actual FQDN
	mut config_values := ConfigValues{
		hostname:               k8app.hostname
		backends:               ''
		namespace:              k8app.namespace
		nextcloud_storage_size: installer.nextcloud_storage_size
		postgres_storage_size:  installer.postgres_storage_size
		admin_user:             installer.admin_user
		admin_password:         installer.admin_password
		db_name:                installer.db_name
		db_user:                installer.db_user
		db_password:            installer.db_password
		postgres_host:          'nextcloud-postgres'
		redis_host:             installer.redis_host
		fqdn:                   fqdn
	}
	
	// Generate Secrets YAML
	secrets_yaml := $tmpl('./templates/secrets.yaml')
	mut secrets_path := pathlib.get_file(
		path:   installer.secrets_path
		create: true
		check:  true
	)!
	secrets_path.write(secrets_yaml)!
	console.print_info('Secrets configuration file generated.')
	
	// Generate PostgreSQL YAML
	postgres_yaml := $tmpl('./templates/postgres.yaml')
	mut postgres_path := pathlib.get_file(path: installer.postgres_path, create: true)!
	postgres_path.write(postgres_yaml)!
	console.print_info('PostgreSQL configuration file generated.')
	
	// Generate Redis YAML
	redis_yaml := $tmpl('./templates/redis.yaml')
	mut redis_path := pathlib.get_file(path: installer.redis_path, create: true)!
	redis_path.write(redis_yaml)!
	console.print_info('Redis configuration file generated.')
	
	// Generate Nextcloud YAML
	nextcloud_yaml := $tmpl('./templates/nextcloud.yaml')
	mut nextcloud_path := pathlib.get_file(path: installer.nextcloud_path, create: true)!
	nextcloud_path.write(nextcloud_yaml)!
	console.print_info('Nextcloud configuration file generated.')
	
	console.print_info('All configuration files generated successfully.')
}


/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !NextcloudK8SInstaller {
	mut obj := encoderhero.decode[NextcloudK8SInstaller](heroscript)!
	return obj
}
