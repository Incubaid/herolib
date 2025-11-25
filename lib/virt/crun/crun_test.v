module crun

import x.json2

fn test_factory_creation() {
	mut configs := map[string]&CrunConfig{}
	config := new(mut configs, name: 'test')!
	assert config.name == 'test'
	assert config.spec.oci_version == '1.0.2'
}

fn test_json_generation() {
	mut configs := map[string]&CrunConfig{}
	mut config := new(mut configs, name: 'test')!
	json_str := config.to_json()!

	// Parse back to verify structure
	parsed := json2.decode[json2.Any](json_str)!
	parsed_map := parsed.as_map()

	oci_version := parsed_map['ociVersion']!
	assert oci_version.str() == '1.0.2'

	process := parsed_map['process']!
	process_map := process.as_map()
	terminal := process_map['terminal']!
	assert terminal.bool() == true
}

fn test_configuration_methods() {
	mut configs := map[string]&CrunConfig{}
	mut config := new(mut configs, name: 'test')!

	// Set configuration (methods don't return self for chaining)
	config.set_command(['/bin/echo', 'hello'])
	config.set_working_dir('/tmp')
	config.set_hostname('test-host')

	assert config.spec.process.args == ['/bin/echo', 'hello']
	assert config.spec.process.cwd == '/tmp'
	assert config.spec.hostname == 'test-host'
}

fn test_validation() {
	mut configs := map[string]&CrunConfig{}
	mut config := new(mut configs, name: 'test')!

	// Should validate successfully with defaults
	config.validate()!

	// Should fail with empty args
	config.spec.process.args = []
	if _ := config.validate() {
		assert false, 'validation should have failed'
	} else {
		// Expected to fail
	}
}

fn test_heropods_compatibility() {
	mut configs := map[string]&CrunConfig{}
	mut config := new(mut configs, name: 'heropods')!

	// The default config should match heropods template structure
	json_str := config.to_json()!
	parsed := json2.decode[json2.Any](json_str)!
	parsed_map := parsed.as_map()

	// Check key fields match template
	oci_version := parsed_map['ociVersion']!
	assert oci_version.str() == '1.0.2'

	process := parsed_map['process']!
	process_map := process.as_map()
	no_new_privs := process_map['noNewPrivileges']!
	assert no_new_privs.bool() == true

	capabilities := process_map['capabilities']!
	capabilities_map := capabilities.as_map()
	bounding := capabilities_map['bounding']!
	bounding_array := bounding.arr()
	bounding_strings := bounding_array.map(it.str())
	assert 'CAP_AUDIT_WRITE' in bounding_strings
	assert 'CAP_KILL' in bounding_strings
	assert 'CAP_NET_BIND_SERVICE' in bounding_strings
}
