module openrouter

fn test_factory() {
	mut client := get(name: 'default', create: true)!
	assert client.name == 'default'
	assert client.url == 'https://openrouter.ai/api/v1'
	assert client.model_default == 'qwen/qwen-2.5-coder-32b-instruct'
}

fn test_client_creation() {
	mut client := new(name: 'test_client')!
	assert client.name == 'test_client'
}
