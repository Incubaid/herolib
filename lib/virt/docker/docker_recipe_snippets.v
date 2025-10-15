module docker

// import incubaid.herolib.develop.gittools
// import incubaid.herolib.core.pathlib

pub fn (mut r DockerBuilderRecipe) add_zinit() ! {
	mut pkg_manager := 'apk add'
	if r.platform == .ubuntu {
		pkg_manager = 'apt install'
	}
	r.add_run(
		cmd: '
			${pkg_manager} wget
    	wget https://github.com/threefoldtech/zinit/releases/download/v0.2.5/zinit -O /sbin/zinit
    	chmod +x /sbin/zinit
		touch /etc/environment
		mkdir -p /etc/zinit/
	'
	)!

	r.add_entrypoint(cmd: '/sbin/zinit init --container')!
}

@[params]
pub struct ExecuteArgs {
pub mut:
	source string // is the filename, needs to be embedded
	debug  bool
}

// execute the file as embedded
pub fn (mut r DockerBuilderRecipe) execute(args ExecuteArgs) ! {
	if args.source == '' {
		return error('source cant be empty, \n ${r}')
	}
	path := args.source
	r.add_file_embedded(source: path, dest: '/tmp/${path}', make_executable: true)!
	if !args.debug {
		r.add_run(cmd: '/tmp/${path}')!
	}
}

pub fn (mut r DockerBuilderRecipe) add_nodejsbuilder() ! {
	r.add_package(name: 'nodejs, npm')!
}

pub fn (mut r DockerBuilderRecipe) add_vbuilder() ! {
	r.add_package(name: 'git, musl-dev, clang, gcc, openssh-client, make')!
	r.add_run(
		cmd: "
		git clone --depth 1 https://github.com/vlang/v /opt/vlang 
		cd  /opt/vlang
		make VFLAGS='-cc gcc' 
		./v -version 
		./v symlink
	"
	)!
	r.add_workdir(workdir: '/opt/vlang')!
}

// add ssh server and init scripts (note: zinit needs to be installed)
pub fn (mut r DockerBuilderRecipe) add_sshserver() ! {
	r.add_package(name: 'openssh-server, bash')!

	r.add_zinit_cmd(
		name:    'sshd-setup'
		oneshot: true
		exec:    "
			rm -rf /etc/ssh
			mkdir -p /etc/ssh
			mkdir -p /run/sshd
			ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519
			cat > /etc/ssh/sshd_config << 'EOF'
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin prohibit-password
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
X11Forwarding no
AllowTcpForwarding yes
AllowAgentForwarding yes
EOF
		"
	)!

	r.add_zinit_cmd(
		name:    'ssh-keys'
		after:   'sshd-setup'
		oneshot: true
		exec:    '
			if [ ! -d /root/.ssh ]; then
				mkdir -m 700 /root/.ssh
			fi

			if [ ! -z "\$SSH_KEY" ]; then
				echo \$SSH_KEY >> /root/.ssh/authorized_keys
				chmod 600 /root/.ssh/authorized_keys
			fi
		'
	)!

	r.add_zinit_cmd(name: 'sshd', exec: '/usr/sbin/sshd -D -e', after: 'sshd-setup')!
}
