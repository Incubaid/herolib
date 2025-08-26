module podman

import time
import freeflowuniverse.herolib.osal.core as osal { exec }
import freeflowuniverse.herolib.data.ipaddress
import freeflowuniverse.herolib.core.texttools

// info see https://docs.podman.io/en/latest/markdown/podman-run.1.html

@[params]
pub struct ContainerCreateArgs {
	name             string
	hostname         string
	forwarded_ports  []string          // ["80:9000/tcp", "1000, 10000/udp"]
	mounted_volumes  []string          // ["/root:/root", ]
	env              map[string]string // map of environment variables that will be passed to the container
	privileged       bool
	remove_when_done bool = true // remove the container when it shuts down
	// Resource limits
	memory             string // Memory limit (e.g. "100m", "2g")
	memory_reservation string // Memory soft limit
	memory_swap        string // Memory + swap limit
	cpus               f64    // Number of CPUs (e.g. 1.5)
	cpu_shares         int    // CPU shares (relative weight)
	cpu_period         int    // CPU CFS period in microseconds (default: 100000)
	cpu_quota          int    // CPU CFS quota in microseconds (e.g. 50000 for 0.5 CPU)
	cpuset_cpus        string // CPUs in which to allow execution (e.g. "0-3", "1,3")
	// Network configuration
	network         string   // Network mode (bridge, host, none, container:id)
	network_aliases []string // Add network-scoped aliases
	exposed_ports   []string // Ports to expose without publishing (e.g. "80/tcp", "53/udp")
	// DNS configuration
	dns_servers []string // Set custom DNS servers
	dns_options []string // Set custom DNS options
	dns_search  []string // Set custom DNS search domains
	// Device configuration
	devices             []string // Host devices to add (e.g. "/dev/sdc:/dev/xvdc:rwm")
	device_cgroup_rules []string // Add rules to cgroup allowed devices list
	// Runtime configuration
	detach      bool = true // Run container in background
	attach      []string // Attach to STDIN, STDOUT, and/or STDERR
	interactive bool     // Keep STDIN open even if not attached (-i)
	// Storage configuration
	rootfs          string   // Use directory as container's root filesystem
	mounts          []string // Mount filesystem (type=bind,src=,dst=,etc)
	volumes         []string // Bind mount a volume (alternative to mounted_volumes)
	published_ports []string // Publish container ports to host (alternative to forwarded_ports)
pub mut:
	image_repo string
	image_tag  string
	command    string = '/bin/bash'
}

// create a new container from an image
pub fn (mut e PodmanFactory) container_create(args_ ContainerCreateArgs) !&Container {
	mut args := args_

	mut cmd := 'podman run --systemd=false'

	// Handle detach/attach options
	if args.detach {
		cmd += ' -d'
	}
	for stream in args.attach {
		cmd += ' -a ${stream}'
	}

	if args.name != '' {
		cmd += ' --name ${texttools.name_fix(args.name)}'
	}

	if args.hostname != '' {
		cmd += ' --hostname ${args.hostname}'
	}

	if args.privileged {
		cmd += ' --privileged'
	}

	if args.remove_when_done {
		cmd += ' --rm'
	}

	// Handle interactive mode
	if args.interactive {
		cmd += ' -i'
	}

	// Handle rootfs
	if args.rootfs != '' {
		cmd += ' --rootfs ${args.rootfs}'
	}

	// Add mount points
	for mount in args.mounts {
		cmd += ' --mount ${mount}'
	}

	// Add volumes (--volume syntax)
	for volume in args.volumes {
		cmd += ' --volume ${volume}'
	}

	// Add published ports (--publish syntax)
	for port in args.published_ports {
		cmd += ' --publish ${port}'
	}

	// Add resource limits
	if args.memory != '' {
		cmd += ' --memory ${args.memory}'
	}

	if args.memory_reservation != '' {
		cmd += ' --memory-reservation ${args.memory_reservation}'
	}

	if args.memory_swap != '' {
		cmd += ' --memory-swap ${args.memory_swap}'
	}

	if args.cpus > 0 {
		cmd += ' --cpus ${args.cpus}'
	}

	if args.cpu_shares > 0 {
		cmd += ' --cpu-shares ${args.cpu_shares}'
	}

	if args.cpu_period > 0 {
		cmd += ' --cpu-period ${args.cpu_period}'
	}

	if args.cpu_quota > 0 {
		cmd += ' --cpu-quota ${args.cpu_quota}'
	}

	if args.cpuset_cpus != '' {
		cmd += ' --cpuset-cpus ${args.cpuset_cpus}'
	}

	// Add network configuration
	if args.network != '' {
		cmd += ' --network ${args.network}'
	}

	// Add network aliases
	for alias in args.network_aliases {
		cmd += ' --network-alias ${alias}'
	}

	// Add exposed ports
	for port in args.exposed_ports {
		cmd += ' --expose ${port}'
	}

	// Add devices
	for device in args.devices {
		cmd += ' --device ${device}'
	}

	// Add device cgroup rules
	for rule in args.device_cgroup_rules {
		cmd += ' --device-cgroup-rule ${rule}'
	}

	// Add DNS configuration
	for server in args.dns_servers {
		cmd += ' --dns ${server}'
	}

	for opt in args.dns_options {
		cmd += ' --dns-option ${opt}'
	}

	for search in args.dns_search {
		cmd += ' --dns-search ${search}'
	}

	// Add port forwarding
	for port in args.forwarded_ports {
		cmd += ' -p ${port}'
	}

	// Add volume mounts
	for volume in args.mounted_volumes {
		cmd += ' -v ${volume}'
	}

	// Add environment variables
	for key, value in args.env {
		cmd += ' -e ${key}=${value}'
	}

	// Add image name and tag
	mut image_name := args.image_repo
	if args.image_tag != '' {
		image_name += ':${args.image_tag}'
	}
	cmd += ' ${image_name}'

	// Add command if specified
	if args.command != '' {
		cmd += ' ${args.command}'
	}

	// Create the container
	mut ljob := exec(cmd: cmd, stdout: false)!
	container_id := ljob.output.trim_space()

	// Reload containers to get the new one
	e.load()!

	// Return the newly created container
	return e.container_get(name: args.name, id: container_id)!
}
