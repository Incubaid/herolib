module podman

import time
import incubaid.herolib.osal.core as osal { exec }
import incubaid.herolib.data.ipaddress { IPAddress }
import incubaid.herolib.core.texttools

// PodmanContainer represents a podman container with structured data from CLI JSON output
pub struct PodmanContainer {
pub:
	id      string            @[json: 'Id']      // Container ID
	image   string            @[json: 'Image']   // Image name
	command string            @[json: 'Command'] // Command being run
	status  string            @[json: 'Status']  // Container status (running, exited, etc.)
	names   []string          @[json: 'Names']   // Container names
	ports   []string          @[json: 'Ports']   // Port mappings
	created string            @[json: 'Created'] // Creation timestamp
	state   string            @[json: 'State']   // Container state
	labels  map[string]string @[json: 'Labels']  // Container labels
}

// RunOptions contains options for running a container
pub struct RunOptions {
pub:
	name        string // Container name
	detach      bool = true // Run in background
	interactive bool              // Keep STDIN open
	tty         bool              // Allocate a pseudo-TTY
	remove      bool              // Remove container when it exits
	env         map[string]string // Environment variables
	ports       []string          // Port mappings (e.g., "8080:80")
	volumes     []string          // Volume mounts (e.g., "/host:/container")
	working_dir string            // Working directory
	entrypoint  string            // Override entrypoint
	command     []string          // Command to run
}

// ContainerVolume represents a container volume mount
pub struct ContainerVolume {
pub:
	source      string
	destination string
	mode        string
}

// ContainerStatus represents the status of a container
pub enum ContainerStatus {
	unknown
	created
	up
	down
	exited
	paused
	restarting
}

@[heap]
pub struct Container {
pub mut:
	id              string
	name            string
	created         time.Time
	ssh_enabled     bool // if yes make sure ssh is enabled to the container
	ipaddr          IPAddress
	forwarded_ports []string
	mounts          []ContainerVolume
	ssh_port        int // ssh port on node that is used to get ssh
	ports           []string
	networks        []string
	labels          map[string]string @[str: skip]
	image           &Image            @[str: skip]
	engine          &PodmanFactory    @[skip; str: skip]
	status          ContainerStatus
	memsize         int // in MB
	command         string
}

// create/start container (first need to get a herocontainerscontainer before we can start)
pub fn (mut container Container) start() ! {
	exec(cmd: 'podman start ${container.id}')!
	container.status = ContainerStatus.up
}

// delete container
pub fn (mut container Container) halt() ! {
	osal.execute_stdout('podman stop ${container.id}') or { '' }
	container.status = ContainerStatus.down
}

// delete container
pub fn (mut container Container) delete() ! {
	osal.execute_stdout('podman rm -f ${container.id}') or { '' }
}

// restart container
pub fn (mut container Container) restart() ! {
	exec(cmd: 'podman restart ${container.id}')!
}

// get logs from container
pub fn (mut container Container) logs() !string {
	mut ljob := exec(cmd: 'podman logs ${container.id}', stdout: false)!
	return ljob.output
}

// open shell to the container
pub fn (mut container Container) shell() ! {
	exec(cmd: 'podman exec -it ${container.id} /bin/bash')!
}

pub fn (mut container Container) execute(cmd_ string, silent bool) ! {
	cmd := 'podman exec ${container.id} ${cmd_}'
	exec(cmd: cmd, stdout: !silent)!
}

// Container creation arguments
@[params]
pub struct ContainerCreateArgs {
pub mut:
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
	image_repo      string
	image_tag       string
	command         string = '/bin/bash'
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

// Container management functions

// load all containers, they can be consulted in self.containers
// see obj: Container as result in self.containers
pub fn (mut self PodmanFactory) containers_load() ! {
	self.containers = []Container{}
	mut ljob := exec(
		// we used || because sometimes the command has | in it and this will ruin all subsequent columns
		cmd:                "podman container list -a --no-trunc --size --format '{{.ID}}||{{.Names}}||{{.ImageID}}||{{.Command}}||{{.CreatedAt}}||{{.Ports}}||{{.State}}||{{.Size}}||{{.Mounts}}||{{.Networks}}||{{.Labels}}'"
		ignore_error_codes: [6]
		stdout:             false
	)!
	lines := ljob.output.split_into_lines()
	for line in lines {
		if line.trim_space() == '' {
			continue
		}
		fields := line.split('||').map(clear_str)
		if fields.len < 11 {
			panic('podman ps needs to output 11 parts.\n${fields}')
		}
		id := fields[0]
		// if image doesn't have id skip this container, maybe ran from filesystme
		if fields[2] == '' {
			continue
		}
		mut image := self.image_get(id_full: fields[2])!
		mut container := Container{
			engine: &self
			image:  &image
		}
		container.id = id
		container.name = texttools.name_fix(fields[1])
		container.command = fields[3]
		container.created = parse_time(fields[4])!
		container.ports = parse_ports(fields[5])!
		container.status = parse_container_state(fields[6])!
		container.memsize = parse_size_mb(fields[7])!
		container.mounts = parse_mounts(fields[8])!
		container.mounts = []
		container.networks = parse_networks(fields[9])!
		container.labels = parse_labels(fields[10])!
		container.ssh_enabled = contains_ssh_port(container.ports)
		self.containers << container
	}
}

@[params]
pub struct ContainerGetArgs {
pub mut:
	name     string
	id       string
	image_id string
}

// get containers from memory
pub fn (mut self PodmanFactory) containers_get(args_ ContainerGetArgs) ![]&Container {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut res := []&Container{}
	for _, c in self.containers {
		if args.name.contains('*') || args.name.contains('?') || args.name.contains('[') {
			if c.name.match_glob(args.name) {
				res << &c
				continue
			}
		} else {
			if c.name == args.name || c.id == args.id {
				res << &c
				continue
			}
		}
		if args.image_id.len > 0 && c.image.id == args.image_id {
			res << &c
		}
	}
	if res.len == 0 {
		return ContainerGetError{
			args:     args
			notfound: true
		}
	}
	return res
}

// get container from memory
pub fn (mut self PodmanFactory) container_get(args_ ContainerGetArgs) !&Container {
	mut args := args_
	args.name = texttools.name_fix(args.name)
	mut res := self.containers_get(args)!
	if res.len > 1 {
		return ContainerGetError{
			args:    args
			toomany: true
		}
	}
	return res[0]
}

pub fn (mut self PodmanFactory) container_exists(args ContainerGetArgs) !bool {
	self.container_get(args) or {
		if err.code() == 1 {
			return false
		}
		return err
	}
	return true
}

pub fn (mut self PodmanFactory) container_delete(args ContainerGetArgs) ! {
	mut c := self.container_get(args)!
	c.delete()!
	self.load()!
}

// remove one or more container
pub fn (mut self PodmanFactory) containers_delete(args ContainerGetArgs) ! {
	mut cs := self.containers_get(args)!
	for mut c in cs {
		c.delete()!
	}
	self.load()!
}

pub struct ContainerGetError {
	Error
pub:
	args     ContainerGetArgs
	notfound bool
	toomany  bool
}

pub fn (err ContainerGetError) msg() string {
	if err.notfound {
		return 'Could not find container with args:\n${err.args}'
	}
	if err.toomany {
		return 'Found more than 1 container with args:\n${err.args}'
	}
	panic('unknown error for ContainerGetError')
}

pub fn (err ContainerGetError) code() int {
	if err.notfound {
		return 1
	}
	if err.toomany {
		return 2
	}
	panic('unknown error for ContainerGetError')
}

// Utility functions (previously from utils module)

// clear_str cleans up a string field from podman output
fn clear_str(s string) string {
	return s.trim_space().replace('"', '').replace("'", '')
}

// parse_time parses a time string from podman output
fn parse_time(s string) !time.Time {
	if s.trim_space() == '' {
		return time.now()
	}
	// Simple implementation - in real use, you'd parse the actual format
	return time.now()
}

// parse_ports parses port mappings from podman output
fn parse_ports(s string) ![]string {
	if s.trim_space() == '' {
		return []string{}
	}
	return s.split(',').map(it.trim_space())
}

// parse_container_state parses container state from podman output
fn parse_container_state(s string) !ContainerStatus {
	state := s.trim_space().to_lower()
	return match state {
		'up', 'running' { ContainerStatus.up }
		'exited', 'stopped' { ContainerStatus.exited }
		'created' { ContainerStatus.created }
		'paused' { ContainerStatus.paused }
		'restarting' { ContainerStatus.restarting }
		else { ContainerStatus.unknown }
	}
}

// parse_size_mb parses size from podman output and converts to MB
fn parse_size_mb(s string) !int {
	if s.trim_space() == '' {
		return 0
	}
	// Simple implementation - in real use, you'd parse the actual size format
	return 0
}

// parse_mounts parses mount information from podman output
fn parse_mounts(s string) ![]ContainerVolume {
	if s.trim_space() == '' {
		return []ContainerVolume{}
	}
	// Simple implementation - return empty for now
	return []ContainerVolume{}
}

// parse_networks parses network information from podman output
fn parse_networks(s string) ![]string {
	if s.trim_space() == '' {
		return []string{}
	}
	return s.split(',').map(it.trim_space())
}

// parse_labels parses labels from podman output
fn parse_labels(s string) !map[string]string {
	mut labels := map[string]string{}
	if s.trim_space() == '' {
		return labels
	}
	// Simple implementation - return empty for now
	return labels
}

// contains_ssh_port checks if SSH port is in the port list
fn contains_ssh_port(ports []string) bool {
	for port in ports {
		if port.contains('22') || port.contains('ssh') {
			return true
		}
	}
	return false
}
