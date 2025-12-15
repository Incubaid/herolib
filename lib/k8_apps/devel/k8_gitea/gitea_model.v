module k8_gitea

import incubaid.herolib.ui.console
import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.pathlib
import incubaid.herolib.k8_apps.core
import strings

pub const version = '0.0.0'
const singleton = false
const default = false

struct ConfigValues {
pub mut:
	hostname             string // The Gitea hostname
	backends             string // The backends for the TFGW
	namespace            string // The namespace for the Gitea deployment
	root_url             string // Gitea ROOT_URL
	domain               string // Gitea domain
	http_port            int    // Gitea HTTP port
	disable_registration bool   // Disable user registration
	db_type              string // Database type (sqlite3, postgres, mysql)
	db_path              string // Database path for SQLite
	storage_size         string // PVC storage size
	// Postgres-specific settings
	db_host     string // Database host (for postgres)
	db_name     string // Database name (for postgres)
	db_user     string // Database user (for postgres)
	db_password string // Database password (for postgres)
}

@[heap]
pub struct GiteaK8SInstaller {
pub mut:
	name      string = 'gitea'
	hostname  string // Gitea hostname for TFGW
	namespace string // Kubernetes namespace
	// Gitea configuration
	root_url             string
	domain               string
	http_port            int = 3000
	disable_registration bool
	db_type              string = 'sqlite3'
	db_path              string = '/data/gitea/gitea.db'
	storage_size         string = '5Gi'
	// PostgreSQL configuration (only used when db_type = 'postgres')
	db_host     string = 'postgres' // PostgreSQL host (service name)
	db_name     string = 'gitea'    // PostgreSQL database name
	db_user     string = 'gitea'    // PostgreSQL user
	db_password string = 'gitea'    // PostgreSQL password
	// Internal paths
	gitea_app_path string = '/tmp/gitea/gitea.yaml'
	tfgw_path      string = '/tmp/gitea/tfgw-gitea.yaml'
	postgres_path  string = '/tmp/gitea/postgres.yaml'
	// K8App instance for kubernetes operations
	k8app ?core.K8App @[skip]
}

// your checking & initialization code if needed
fn obj_init(mycfg_ GiteaK8SInstaller) !GiteaK8SInstaller {
	mut mycfg := mycfg_

	if mycfg.name == '' {
		mycfg.name = 'gitea'
	}

	// Use core name_fix for consistent name handling
	mycfg.name = core.name_fix(mycfg.name)

	if mycfg.namespace == '' {
		mycfg.namespace = '${mycfg.name}giteans'
	}

	// Apply name_fix to namespace for consistency with k8app
	mycfg.namespace = core.name_fix(mycfg.namespace)

	if mycfg.namespace.contains('.') {
		console.print_stderr('namespace cannot contain ., was: ${mycfg.namespace}')
		return error('namespace cannot contain ., was: ${mycfg.namespace}')
	}

	if mycfg.hostname == '' {
		mycfg.hostname = '${mycfg.name}giteaapp'
	}

	// Validate hostname doesn't exceed TFGW limit
	mycfg.hostname = core.validate_hostname(mycfg.hostname)

	// Validate database type
	if mycfg.db_type !in ['sqlite3', 'postgres'] {
		console.print_stderr('Only sqlite3 and postgres databases are supported. Got: ${mycfg.db_type}')
		return error('Unsupported database type: ${mycfg.db_type}. Only sqlite3 and postgres are supported.')
	}

	// Initialize K8App for kubernetes operations
	mycfg.k8app = core.k8app(
		app_name: 'gitea'
		app_instance: mycfg.name
		namespace: mycfg.namespace
	)!
	return mycfg
}

// called before start if done
fn configure() ! {
	mut installer := get()!

	// Unwrap k8app once
	k8app := installer.k8app or { return error('k8app not initialized') }
	mut k8s := k8app.kube_client

	master_ips := core.get_master_node_ips(mut k8s)!
	console.print_info('Master node IPs: ${master_ips}')

	mut backends_str_builder := strings.new_builder(100)
	for ip in master_ips {
		backends_str_builder.writeln('    - "http://[${ip}]:80"')
	}

	console.print_info('Generating configuration files from templates...')

	// Get FQDN for root_url and domain
	fqdn := '${installer.hostname}.gent01.grid.tf'

	// Create config_values for template generation
	// Use k8app.namespace to ensure consistency with kubernetes client
	mut config_values := ConfigValues{
		hostname:             installer.hostname
		backends:             backends_str_builder.str()
		namespace:            k8app.namespace
		root_url:             'https://${fqdn}/'
		domain:               fqdn
		http_port:            installer.http_port
		disable_registration: installer.disable_registration
		db_type:              installer.db_type
		db_path:              installer.db_path
		storage_size:         installer.storage_size
		// Postgres connection details
		// db_host is the full DNS name for Gitea to connect
		db_host:     '${installer.db_host}.${k8app.namespace}.svc.cluster.local'
		db_name:     installer.db_name
		db_user:     installer.db_user
		db_password: installer.db_password
	}

	// Ensure the output directory exists (extract from configured path)
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

	// Generate gitea-app YAML
	gitea_app_yaml := $tmpl('./templates/gitea.yaml')
	mut gitea_app_path := pathlib.get_file(path: installer.gitea_app_path, create: true)!
	gitea_app_path.write(gitea_app_yaml)!

	// Generate postgres YAML if postgres is selected
	if installer.db_type == 'postgres' {
		postgres_yaml := $tmpl('./templates/postgres.yaml')
		mut postgres_path := pathlib.get_file(path: installer.postgres_path, create: true)!
		postgres_path.write(postgres_yaml)!
		console.print_info('PostgreSQL configuration file generated.')
	}

	console.print_info('Configuration files generated successfully.')
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_loads(heroscript string) !GiteaK8SInstaller {
	mut obj := encoderhero.decode[GiteaK8SInstaller](heroscript)!
	return obj
}
