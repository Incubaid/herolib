module kubernetes

import json
import incubaid.herolib.data.markdown
import incubaid.herolib.core.pathlib
import os

// Parse YAML file and return validation result
pub fn yaml_validate(yaml_path string) !K8sValidationResult {
	mut file := pathlib.get(yaml_path)

	if !file.exists() {
		return error('YAML file not found: ${yaml_path}')
	}

	yaml_content := file.read()!

	// Extract kind and apiVersion from YAML
	lines := yaml_content.split('\n')
	mut kind := ''
	mut api_version := ''
	mut metadata_name := ''
	mut metadata_namespace := 'default'

	for line in lines {
		if line.starts_with('kind:') {
			kind = line.replace('kind:', '').trim_space()
		}
		if line.starts_with('apiVersion:') {
			api_version = line.replace('apiVersion:', '').trim_space()
		}
		if line.contains('name:') && line.trim_space().starts_with('name:') {
			metadata_name = line.replace('name:', '').trim_space()
		}
		if line.contains('namespace:') && line.trim_space().starts_with('namespace:') {
			metadata_namespace = line.replace('namespace:', '').trim_space()
		}
	}

	mut errors := []string{}

	if kind.len == 0 {
		errors << 'Missing "kind" field'
	}
	if api_version.len == 0 {
		errors << 'Missing "apiVersion" field'
	}
	if metadata_name.len == 0 {
		errors << 'Missing metadata.name field'
	}

	// Validate kind values
	valid_kinds := ['Pod', 'Deployment', 'Service', 'ConfigMap', 'Secret', 'StatefulSet',
		'DaemonSet', 'Job', 'CronJob', 'Ingress', 'PersistentVolume', 'PersistentVolumeClaim']
	if kind !in valid_kinds {
		errors << 'Invalid kind: ${kind}. Valid kinds: ${valid_kinds.join(", ")}'
	}

	return K8sValidationResult{
		valid: errors.len == 0
		kind: kind
		api_version: api_version
		metadata: K8sMetadata{
			name: metadata_name
			namespace: metadata_namespace
		}
		errors: errors
	}
}

// Generate YAML from model
pub fn yaml_from_deployment(spec DeploymentSpec) !string {
	mut yaml := 'apiVersion: apps/v1\nkind: Deployment\nmetadata:\n'
	yaml += '  name: ${spec.metadata.name}\n'
	yaml += '  namespace: ${spec.metadata.namespace}\n'

	if spec.metadata.labels.len > 0 {
		yaml += '  labels:\n'
		for key, value in spec.metadata.labels {
			yaml += '    ${key}: ${value}\n'
		}
	}

	yaml += 'spec:\n'
	yaml += '  replicas: ${spec.replicas}\n'
	yaml += '  selector:\n'
	yaml += '    matchLabels:\n'
	for key, value in spec.selector {
		yaml += '      ${key}: ${value}\n'
	}

	yaml += '  template:\n'
	yaml += '    metadata:\n'
	yaml += '      labels:\n'
	for key, value in spec.selector {
		yaml += '        ${key}: ${value}\n'
	}

	yaml += '    spec:\n'
	yaml += '      containers:\n'
	for container in spec.template.containers {
		yaml += '      - name: ${container.name}\n'
		yaml += '        image: ${container.image}\n'
		yaml += '        imagePullPolicy: ${container.image_pull_policy}\n'

		if container.ports.len > 0 {
			yaml += '        ports:\n'
			for port in container.ports {
				yaml += '        - name: ${port.name}\n'
				yaml += '          containerPort: ${port.container_port}\n'
				yaml += '          protocol: ${port.protocol}\n'
			}
		}

		if container.env.len > 0 {
			yaml += '        env:\n'
			for env in container.env {
				yaml += '        - name: ${env.name}\n'
				yaml += '          value: "${env.value}"\n'
			}
		}
	}

	return yaml
}

pub fn yaml_from_service(spec ServiceSpec) !string {
	mut yaml := 'apiVersion: v1\nkind: Service\nmetadata:\n'
	yaml += '  name: ${spec.metadata.name}\n'
	yaml += '  namespace: ${spec.metadata.namespace}\n'

	yaml += 'spec:\n'
	yaml += '  type: ${spec.service_type}\n'
	yaml += '  selector:\n'
	for key, value in spec.selector {
		yaml += '    ${key}: ${value}\n'
	}

	yaml += '  ports:\n'
	for port in spec.ports {
		yaml += '  - name: ${port.name}\n'
		yaml += '    protocol: ${port.protocol}\n'
		yaml += '    port: ${port.port}\n'
		yaml += '    targetPort: ${port.target_port}\n'
		if port.node_port > 0 {
			yaml += '    nodePort: ${port.node_port}\n'
		}
	}

	return yaml
}

pub fn yaml_from_configmap(spec ConfigMapSpec) !string {
	mut yaml := 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n'
	yaml += '  name: ${spec.metadata.name}\n'
	yaml += '  namespace: ${spec.metadata.namespace}\n'
	yaml += 'data:\n'

	for key, value in spec.data {
		yaml += '  ${key}: |\n'
		// Indent multiline values
		lines := value.split('\n')
		for line in lines {
			yaml += '    ${line}\n'
		}
	}

	return yaml
}