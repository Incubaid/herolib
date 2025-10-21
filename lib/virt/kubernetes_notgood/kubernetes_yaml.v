module kubernetes

import encoding.yaml

// Serialize Kubernetes resource to YAML
pub fn to_yaml[T](resource T) !string {
	// TODO: Use V's YAML encoding to serialize
	return encode_to_yaml(resource)!
}

// Deserialize YAML to Kubernetes resource
pub fn from_yaml[T](content string) !T {
	// TODO: Use V's YAML decoding to parse
	return decode_from_yaml[T](content)!
}

// Helper to handle YAML document conversion
fn encode_to_yaml[T](resource T) !string {
	return yaml.encode(resource)!
}

fn decode_from_yaml[T](content string) !T {
	return yaml.decode[T](content)!
}

// Multi-document YAML support
pub fn to_yaml_multi[T](resources []T) !string {
	mut result := ''
	for i, resource in resources {
		result += '---\n'
		result += to_yaml(resource)!
		if i < resources.len - 1 {
			result += '\n'
		}
	}
	return result
}

pub fn from_yaml_multi[T](content string) ![]T {
	mut result := []T{}
	docs := content.split('---')
	
	for doc in docs {
		trimmed := doc.trim_space()
		if trimmed.len == 0 {
			continue
		}
		resource := from_yaml[T](trimmed)!
		result << resource
	}
	
	return result
}