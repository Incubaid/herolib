#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

// import incubaid.herolib.core.base
import incubaid.herolib.clients.runpod
import json
import x.json2

// Create client with direct API key
// This uses RUNPOD_API_KEY from environment
mut rp := runpod.get()!

// Create a new on demand pod
on_demand_pod_response := rp.create_on_demand_pod(
	name:                 'RunPod Tensorflow'
	image_name:           'runpod/tensorflow'
	cloud_type:           'ALL'
	gpu_count:            1
	volume_in_gb:         5
	container_disk_in_gb: 5
	min_memory_in_gb:     4
	min_vcpu_count:       1
	gpu_type_id:          'NVIDIA RTX A4000'
	ports:                '8888/http'
	volume_mount_path:    '/workspace'
	env:                  [
		runpod.EnvironmentVariableInput{
			key:   'JUPYTER_PASSWORD'
			value: 'rn51hunbpgtltcpac3ol'
		},
	]
)!

println('Created pod with ID: ${on_demand_pod_response.id}')

// create a spot pod
spot_pod_response := rp.create_spot_pod(
	port:                 1826
	bid_per_gpu:          0.2
	cloud_type:           'SECURE'
	gpu_count:            1
	volume_in_gb:         5
	container_disk_in_gb: 5
	min_vcpu_count:       1
	min_memory_in_gb:     4
	gpu_type_id:          'NVIDIA RTX A4000'
	name:                 'RunPod Pytorch'
	image_name:           'runpod/pytorch'
	docker_args:          ''
	ports:                '8888/http'
	volume_mount_path:    '/workspace'
	env:                  [
		runpod.EnvironmentVariableInput{
			key:   'JUPYTER_PASSWORD'
			value: 'rn51hunbpgtltcpac3ol'
		},
	]
)!
println('Created spot pod with ID: ${spot_pod_response.id}')

// stop on-demand pod
stop_on_demand_pod := rp.stop_pod(
	pod_id: '${on_demand_pod_response.id}'
)!
println('Stopped on-demand pod with ID: ${stop_on_demand_pod.id}')

// stop spot pod
stop_spot_pod := rp.stop_pod(
	pod_id: '${spot_pod_response.id}'
)!
println('Stopped spot pod with ID: ${stop_spot_pod.id}')

// start on-demand pod
start_on_demand_pod := rp.start_on_demand_pod(pod_id: '${on_demand_pod_response.id}', gpu_count: 1)!
println('Started on demand pod with ID: ${on_demand_pod_response.id}')

// start spot pod
start_spot_pod := rp.start_spot_pod(
	pod_id:      '${spot_pod_response.id}'
	gpu_count:   1
	bid_per_gpu: 0.2
)!
println('Started spot pod with ID: ${spot_pod_response.id}')

get_pod := rp.get_pod(
	pod_id: '${spot_pod_response.id}'
)!
println('Get pod result: ${get_pod}')

rp.terminate_pod(pod_id: '${spot_pod_response.id}')!
println('pod with id ${spot_pod_response.id} is terminated')

rp.terminate_pod(pod_id: '${on_demand_pod_response.id}')!
println('pod with id ${on_demand_pod_response.id} is terminated')
