module kubernetes

import time
import os

fn test_model_creation() ! {
	mut deployment := DeploymentSpec{
		metadata: K8sMetadata{
			name: 'test-app'
			namespace: 'default'
		}
		replicas: 3
		selector: {
			'app': 'test-app'
		}
		template: PodSpec{
			metadata: K8sMetadata{
				name: 'test-app-pod'
				namespace: 'default'
			}
			containers: [
				ContainerSpec{
					name: 'app'
					image: 'nginx:latest'
					ports: [
						ContainerPort{
							name: 'http'
							container_port: 80
						}
					]
				}
			]
		}
	}

	yaml := yaml_from_deployment(deployment)!
	assert yaml.contains('apiVersion: apps/v1')
	assert yaml.contains('kind: Deployment')
	assert yaml.contains('test-app')
}

fn test_yaml_validation() ! {
	// Create test YAML file
	test_yaml := '''
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-deployment
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test
  template:
    metadata:
      labels:
        app: test
    spec:
      containers:
      - name: app
        image: nginx:latest
'''

	test_file := '/tmp/test-deployment.yaml'
	os.write_file(test_file, test_yaml)!

	result := yaml_validate(test_file)!
	assert result.valid
	assert result.kind == 'Deployment'
	assert result.metadata.name == 'test-deployment'

	os.rm(test_file)!
}