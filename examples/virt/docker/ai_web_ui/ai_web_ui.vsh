#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.virt.docker

mut engine := docker.new(prefix: '', localonly: true)!

mut r := engine.recipe_new(name: 'dev_ubuntu', platform: .ubuntu)

r.add_from(image: 'ubuntu', tag: 'latest')!
r.add_package(name: 'git,curl')!

r.add_zinit()!
r.add_sshserver()!

r.add_run(cmd: 'curl -LsSf https://astral.sh/uv/install.sh | sh')!
r.add_env('PATH', '/root/.local/bin:\$PATH')!
r.add_run(cmd: 'uv python install 3.12')!
r.add_run(cmd: 'uv venv /opt/venv')!
r.add_env('VIRTUAL_ENV', '/opt/venv')!
r.add_env('PATH', '/opt/venv/bin:\$PATH')!
r.add_run(cmd: 'uv pip install open-webui')!
r.add_zinit_cmd(
	exec: "bash -c 'VIRTUAL_ENV=/opt/venv DATA_DIR=~/.open-webui /root/.local/bin/uvx --python 3.12 open-webui serve'"
	name: 'open-webui'
)!

r.add_run(cmd: 'apt-get clean')!
r.add_run(cmd: 'rm -rf /var/lib/apt/lists/*')!

r.build(true)!
