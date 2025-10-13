module docker

import incubaid.herolib.osal.core as osal { exec }
import incubaid.herolib.virt.utils

@[params]
pub struct DockerContainerCreateArgs {
pub mut:
	name             string
	hostname         string
	forwarded_ports  []string          // ["80:9000/tcp", "1000, 10000/udp"]
	mounted_volumes  []string          // ["/root:/root", ]
	env              map[string]string // map of environment variables that will be passed to the container
	privileged       bool
	remove_when_done bool = true // remove the container when it shuts down
	image_repo       string
	image_tag        string
	command          string
}

pub fn (mut e DockerEngine) container_create(args DockerContainerCreateArgs) !&DockerContainer {
	// Validate required parameters
	if args.name.trim_space() == '' {
		return error('Container name cannot be empty')
	}

	// Set default hostname if not provided
	mut hostname := args.hostname
	if hostname.trim_space() == '' {
		hostname = args.name.replace('_', '-')
	}

	mut ports := ''
	mut mounts := ''
	mut env := ''
	mut command := args.command

	// Build environment variables string with proper spacing
	for var, value in args.env {
		if env != '' {
			env += ' '
		}
		env += '-e "${var}=${value}"'
	}

	// Build ports string
	for port in args.forwarded_ports {
		if ports != '' {
			ports += ' '
		}
		ports += '-p ${port}'
	}

	// Build mounts string
	for mount in args.mounted_volumes {
		if mounts != '' {
			mounts += ' '
		}
		mounts += '-v ${mount}'
	}

	// Build image string
	mut image := args.image_repo
	if args.image_tag != '' {
		image += ':${args.image_tag}'
	} else {
		// Check if image exists with 'local' tag first
		mut local_check := exec(cmd: 'docker images ${args.image_repo}:local -q', debug: true)!
		if local_check.output != '' {
			image += ':local'
		} else {
			// Default to latest if no tag specified
			image += ':latest'
		}
	}

	// Set default image and command for threefold
	if image == 'threefold' || image == 'threefold:latest' || image == '' {
		image = 'threefoldtech/grid3_ubuntu_dev'
		command = '/usr/local/bin/boot.sh'
	}

	// Verify image exists locally
	mut image_check := exec(cmd: 'docker images ${image} -q')!
	if image_check.output == '' {
		return error('Docker image not found: ${image}. Please ensure the image exists locally or can be pulled from a registry.')
	}

	privileged := if args.privileged { '--privileged' } else { '' }

	// Add SSH port if not present
	if !utils.contains_ssh_port(args.forwarded_ports) {
		mut port := e.get_free_port() or { return error('No free port available for SSH') }
		if ports != '' {
			ports += ' '
		}
		ports += '-p ${port}:22/tcp'
	}

	// Construct docker run command with proper spacing and escaping
	mut mycmd := 'docker run'
	if hostname != '' {
		mycmd += ' --hostname "${hostname}"'
	}
	if privileged != '' {
		mycmd += ' ${privileged}'
	}
	mycmd += ' --sysctl net.ipv6.conf.all.disable_ipv6=0'
	mycmd += ' --name "${args.name}"'
	if ports != '' {
		mycmd += ' ${ports}'
	}
	if env != '' {
		mycmd += ' ${env}'
	}
	if mounts != '' {
		mycmd += ' ${mounts}'
	}
	mycmd += ' -d -t ${image}'
	if command != '' {
		mycmd += ' ${command}'
	}
	// Execute docker run command
	exec(cmd: mycmd) or {
		return error('Failed to create Docker container:
Command: ${mycmd}
Error: ${err}
Possible causes:
- Invalid image name or tag
- Container name already in use
- Port conflicts
- Insufficient permissions
Please check the error message and try again.')
	}

	// Verify container was created successfully
	e.containers_load() or {
		return error('Container created but failed to reload container list: ${err}')
	}

	mut container := e.container_get(name: args.name) or {
		return error('Container created but not found in container list. This may indicate the container failed to start properly. Check container logs with: docker logs ${args.name}')
	}

	return container
}
