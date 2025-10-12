#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.clients.vastai
import json
import x.json2

// Create client with direct API key
// This uses VASTAI_API_KEY from environment
mut va := vastai.get()!

offers := va.search_offers()!
println('offers: ${offers}')

top_offers := va.get_top_offers(5)!
println('top offers: ${top_offers}')

create_instance_res := va.create_instance(
	id:     top_offers[0].id
	config: vastai.CreateInstanceConfig{
		image: 'pytorch/pytorch:2.5.1-cuda12.4-cudnn9-runtime'
		disk:  10
	}
)!
println('create instance res: ${create_instance_res}')

attach_sshkey_to_instance_res := va.attach_sshkey_to_instance(
	id:      1
	ssh_key: 'ssh-rsa AAAA...'
)!
println('attach sshkey to instance res: ${attach_sshkey_to_instance_res}')

stop_instance_res := va.stop_instance(
	id:    1
	state: 'stopped'
)!
println('stop instance res: ${stop_instance_res}')

destroy_instance_res := va.destroy_instance(
	id: 1
)!
println('destroy instance res: ${destroy_instance_res}')

// For some reason this method returns an error from their server, 500 ERROR
// (request failed with code 500: {"error":"server_error","msg":"Something went wrong on the server"})
launch_instance_res := va.launch_instance(
	// Required
	num_gpus: 1
	gpu_name: 'RTX_3090'
	image:    'vastai/tensorflow'
	disk:     10
	region:   'us-west'

	// Optional
	env: 'user=7amada, home=/home/7amada'
)!
println('destroy instance res: ${launch_instance_res}')

start_instances_res := va.start_instances(
	ids: [1, 2, 3]
)!
println('start instances res: ${start_instances_res}')

start_instance_res := va.start_instance(
	id: 1
)!
println('start instance res: ${start_instance_res}')
