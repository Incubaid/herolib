module crun

fn test_factory_creation() {
	config := new(name: 'test')!
	assert config.name == 'test'
	assert config.spec.version == '1.0.0'
}

fn test_json_generation() {
	mut config := new(name: 'test')!
	json_str := config.to_json()!
	assert json_str.contains('"ociVersion": "1.0.0"')
	assert json_str.contains('"os": "linux"')
}

fn test_configuration_methods() {
	mut config := new(name: 'test')!
	
	config.set_command(['/bin/echo', 'hello'])
		.set_working_dir('/tmp')
		.set_hostname('test-host')
	
	assert config.spec.process.args == ['/bin/echo', 'hello']
	assert config.spec.process.cwd == '/tmp'
	assert config.spec.hostname == 'test-host'
}