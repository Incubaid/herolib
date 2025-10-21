module kubernetes

import incubaid.herolib.lib.virt.kubernetes.kubernetes_models as km
import incubaid.herolib.lib.virt.kubernetes.kubernetes_yaml as ky
import incubaid.herolib.data.ourtime

fn test_object_meta_serialization() {
	mut meta := km.ObjectMeta{
		name: 'my-object'
		namespace: 'default'
		labels: {
			'app': 'test'
			'env': 'dev'
		}
		annotations: {
			'note': 'some annotation'
		}
	}
	
	yaml_str := ky.to_yaml(meta)!
	assert yaml_str.contains('name: my-object')
	assert yaml_str.contains('namespace: default')
	assert yaml_str.contains('app: test')
	assert yaml_str.contains('note: some annotation')
	
	decoded_meta := ky.from_yaml[km.ObjectMeta](yaml_str)!
	assert decoded_meta.name == 'my-object'
	assert decoded_meta.namespace == 'default'
	assert decoded_meta.labels['app'] == 'test'
	assert decoded_meta.annotations['note'] == 'some annotation'
}

fn test_pod_full_serialization() {
	mut pod := km.Pod{
		metadata: km.ObjectMeta{
			name: 'full-pod'
			namespace: 'test-ns'
			labels: { 'run': 'full-pod' }
		}
		spec: km.PodSpec{
			containers: [
				km.Container{
					name: 'main-container'
					image: 'ubuntu:latest'
					ports: [km.ContainerPort{ container_port: 8080, protocol: 'TCP' }]
					env: [
						km.EnvVar{ name: 'ENV_VAR_1', value: 'value1' },
						km.EnvVar{ name: 'ENV_VAR_2', value_from: km.EnvVarSource{ config_map_key_ref: km.ConfigMapKeySelector{ name: 'my-config', key: 'key1' } } }
					]
					resources: km.ResourceRequirements{
						limits: { 'cpu': '100m', 'memory': '128Mi' }
						requests: { 'cpu': '50m', 'memory': '64Mi' }
					}
					liveness_probe: km.Probe{
						http_get: km.HTTPGetAction{ path: '/healthz', port: 8080 }
						initial_delay_seconds: 5
					}
				}
			]
			volumes: [
				km.Volume{
					name: 'config-volume'
					config_map: km.ConfigMapVolumeSource{
						name: 'my-config'
						items: [km.KeyToPath{ key: 'config.txt', path: 'config.txt' }]
					}
				}
			]
		}
	}
	
	yaml_str := ky.to_yaml(pod)!
	assert yaml_str.contains('name: full-pod')
	assert yaml_str.contains('image: ubuntu:latest')
	assert yaml_str.contains('containerPort: 8080')
	assert yaml_str.contains('ENV_VAR_1')
	assert yaml_str.contains('cpu: 100m')
	assert yaml_str.contains('path: /healthz')
	assert yaml_str.contains('name: config-volume')
	
	decoded_pod := ky.from_yaml[km.Pod](yaml_str)!
	assert decoded_pod.metadata.name == 'full-pod'
	assert decoded_pod.spec.containers[0].name == 'main-container'
	assert decoded_pod.spec.containers[0].env[0].name == 'ENV_VAR_1'
	assert decoded_pod.spec.containers[0].resources!.limits['cpu'] == '100m'
	assert decoded_pod.spec.volumes[0].name == 'config-volume'
}

fn test_deployment_serialization() {
	mut deployment := km.Deployment{
		metadata: km.ObjectMeta{
			name: 'my-deployment'
			namespace: 'default'
		}
		spec: km.DeploymentSpec{
			replicas: 3
			selector: km.LabelSelector{
				match_labels: { 'app': 'my-app' }
			}
			template: km.PodTemplateSpec{
				metadata: km.ObjectMeta{
					labels: { 'app': 'my-app' }
				}
				spec: km.PodSpec{
					containers: [
						km.Container{
							name: 'web'
							image: 'my-image:1.0'
						}
					]
				}
			}
		}
	}
	
	yaml_str := ky.to_yaml(deployment)!
	assert yaml_str.contains('name: my-deployment')
	assert yaml_str.contains('replicas: 3')
	assert yaml_str.contains('app: my-app')
	assert yaml_str.contains('image: my-image:1.0')
	
	decoded_deployment := ky.from_yaml[km.Deployment](yaml_str)!
	assert decoded_deployment.metadata.name == 'my-deployment'
	assert decoded_deployment.spec.replicas == 3
	assert decoded_deployment.spec.selector!.match_labels['app'] == 'my-app'
}

fn test_service_serialization() {
	mut service := km.Service{
		metadata: km.ObjectMeta{
			name: 'my-service'
			namespace: 'default'
		}
		spec: km.ServiceSpec{
			service_type: 'NodePort'
			selector: { 'app': 'my-app' }
			ports: [
				km.ServicePort{
					port: 80
					target_port: '8080'
					node_port: 30000
				}
			]
		}
	}
	
	yaml_str := ky.to_yaml(service)!
	assert yaml_str.contains('name: my-service')
	assert yaml_str.contains('type: NodePort')
	assert yaml_str.contains('port: 80')
	assert yaml_str.contains('targetPort: "8080"')
	assert yaml_str.contains('nodePort: 30000')
	
	decoded_service := ky.from_yaml[km.Service](yaml_str)!
	assert decoded_service.metadata.name == 'my-service'
	assert decoded_service.spec.service_type == 'NodePort'
	assert decoded_service.spec.ports[0].port == 80
	assert decoded_service.spec.ports[0].target_port == '8080'
	assert decoded_service.spec.ports[0].node_port == 30000
}

fn test_configmap_serialization() {
	mut configmap := km.ConfigMap{
		metadata: km.ObjectMeta{
			name: 'my-configmap'
			namespace: 'default'
		}
		data: {
			'key1': 'value1'
			'key2': 'value2'
		}
	}
	
	yaml_str := ky.to_yaml(configmap)!
	assert yaml_str.contains('name: my-configmap')
	assert yaml_str.contains('key1: value1')
	
	decoded_configmap := ky.from_yaml[km.ConfigMap](yaml_str)!
	assert decoded_configmap.metadata.name == 'my-configmap'
	assert decoded_configmap.data['key1'] == 'value1'
}

fn test_secret_serialization() {
	mut secret := km.Secret{
		metadata: km.ObjectMeta{
			name: 'my-secret'
			namespace: 'default'
		}
		string_data: {
			'username': 'admin'
			'password': 'password123'
		}
	}
	
	yaml_str := ky.to_yaml(secret)!
	assert yaml_str.contains('name: my-secret')
	assert yaml_str.contains('username: admin')
	
	decoded_secret := ky.from_yaml[km.Secret](yaml_str)!
	assert decoded_secret.metadata.name == 'my-secret'
	assert decoded_secret.string_data['username'] == 'admin'
}

fn test_namespace_serialization() {
	mut namespace := km.Namespace{
		metadata: km.ObjectMeta{
			name: 'my-namespace'
		}
	}
	
	yaml_str := ky.to_yaml(namespace)!
	assert yaml_str.contains('name: my-namespace')
	
	decoded_namespace := ky.from_yaml[km.Namespace](yaml_str)!
	assert decoded_namespace.metadata.name == 'my-namespace'
}

fn test_persistent_volume_claim_serialization() {
	mut pvc := km.PersistentVolumeClaim{
		metadata: km.ObjectMeta{
			name: 'my-pvc'
			namespace: 'default'
		}
		spec: km.PersistentVolumeClaimSpec{
			access_modes: ['ReadWriteOnce']
			resources: km.ResourceRequirements{
				requests: { 'storage': '1Gi' }
			}
			storage_class_name: 'standard'
		}
	}
	
	yaml_str := ky.to_yaml(pvc)!
	assert yaml_str.contains('name: my-pvc')
	assert yaml_str.contains('accessModes:')
	assert yaml_str.contains('- ReadWriteOnce')
	assert yaml_str.contains('storage: 1Gi')
	
	decoded_pvc := ky.from_yaml[km.PersistentVolumeClaim](yaml_str)!
	assert decoded_pvc.metadata.name == 'my-pvc'
	assert decoded_pvc.spec.access_modes[0] == 'ReadWriteOnce'
	assert decoded_pvc.spec.resources.requests['storage'] == '1Gi'
}

fn test_ingress_serialization() {
	mut ingress := km.Ingress{
		metadata: km.ObjectMeta{
			name: 'my-ingress'
			namespace: 'default'
		}
		spec: km.IngressSpec{
			ingress_class_name: 'nginx'
			rules: [
				km.IngressRule{
					host: 'example.com'
					http: km.HTTPIngressRuleValue{
						paths: [
							km.HTTPIngressPath{
								path: '/'
								path_type: 'Prefix'
								backend: km.IngressBackend{
									service: km.IngressServiceBackend{
										name: 'my-service'
										port: km.IngressServiceBackendPort{ number: 80 }
									}
								}
							}
						]
					}
				}
			]
			tls: [
				km.IngressTLS{
					hosts: ['example.com']
					secret_name: 'example-tls'
				}
			]
		}
	}
	
	yaml_str := ky.to_yaml(ingress)!
	assert yaml_str.contains('name: my-ingress')
	assert yaml_str.contains('host: example.com')
	assert yaml_str.contains('path: /')
	assert yaml_str.contains('service:')
	assert yaml_str.contains('name: my-service')
	assert yaml_str.contains('number: 80')
	assert yaml_str.contains('secretName: example-tls')
	
	decoded_ingress := ky.from_yaml[km.Ingress](yaml_str)!
	assert decoded_ingress.metadata.name == 'my-ingress'
	assert decoded_ingress.spec.rules[0].host == 'example.com'
	assert decoded_ingress.spec.rules[0].http!.paths[0].backend.service!.name == 'my-service'
	assert decoded_ingress.spec.tls[0].secret_name == 'example-tls'
}