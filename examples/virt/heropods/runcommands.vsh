#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.heropods

mut heropods_ := heropods.new(
	reset:      false
	use_podman: true
) or { panic('Failed to init HeroPods: ${err}') }

mut container := heropods_.container_new(
	name:              'alpine_demo'
	image:             .custom
	custom_image_name: 'alpine_3_20'
	docker_url:        'docker.io/library/alpine:3.20'
)!

container.start()!
container.exec(cmd: 'ls')!
container.stop()!
