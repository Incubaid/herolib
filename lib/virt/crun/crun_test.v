module crun

import json

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
	parsed := json.decode(map[string]json.Any, json_str)!
	
	assert parsed['ociVersion']! as string == '1.0.2'
	
	process := parsed['process']! as map[string]json.Any
	assert process['terminal']! as bool == true
}

fn test_configuration_methods() {
	mut configs := map[string]&CrunConfig{}
	mut config := new(mut configs, name: 'test')!
	
	config.set_command(['/bin/echo', 'hello'])
		.set_working_dir('/tmp')
		.set_hostname('test-host')
	
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
	parsed := json.decode(map[string]json.Any, json_str)!
	
	// Check key fields match template
	assert parsed['ociVersion']! as string == '1.0.2'
	
	process := parsed['process']! as map[string]json.Any
	assert process['noNewPrivileges']! as bool == true
	
	capabilities := process['capabilities']! as map[string]json.Any
	bounding := capabilities['bounding']! as []json.Any
	assert 'CAP_AUDIT_WRITE' in bounding.map(it as string)
	assert 'CAP_KILL' in bounding.map(it as string)
	assert 'CAP_NET_BIND_SERVICE' in bounding.map(it as string)
}