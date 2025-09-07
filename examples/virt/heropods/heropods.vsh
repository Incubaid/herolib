#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.virt.heropods
// Initialize factory

mut factory := heropods.new(
	reset:      false
	use_podman: true
) or { panic('Failed to init ContainerFactory: ${err}') }

container := factory.new(
	name:              'myalpine'
	image:             .custom
	custom_image_name: 'alpine_3_20'
	docker_url:        'docker.io/library/alpine:3.20'
)!
