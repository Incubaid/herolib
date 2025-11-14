module playcmds

import incubaid.herolib.core.playbook
import incubaid.herolib.apps.biz.erpnext
import incubaid.herolib.clients.giteaclient
import incubaid.herolib.clients.ipapi
import incubaid.herolib.clients.jina
import incubaid.herolib.clients.mailclient
import incubaid.herolib.clients.meilisearch
import incubaid.herolib.clients.mycelium
import incubaid.herolib.clients.mycelium_rpc
import incubaid.herolib.clients.openai
import incubaid.herolib.clients.postgresql_client
import incubaid.herolib.clients.qdrant
import incubaid.herolib.clients.rcloneclient
import incubaid.herolib.clients.runpod
import incubaid.herolib.clients.sendgrid
import incubaid.herolib.clients.vastai
import incubaid.herolib.clients.wireguard
import incubaid.herolib.clients.zerodb_client
import incubaid.herolib.clients.zinit
import incubaid.herolib.develop.heroprompt
import incubaid.herolib.installers.db.meilisearch_installer
import incubaid.herolib.installers.infra.coredns
import incubaid.herolib.installers.infra.gitea
import incubaid.herolib.installers.infra.livekit
import incubaid.herolib.installers.infra.zinit_installer
import incubaid.herolib.installers.k8s.cryptpad
import incubaid.herolib.installers.k8s.element_chat
import incubaid.herolib.installers.lang.golang
import incubaid.herolib.installers.lang.nodejs
import incubaid.herolib.installers.lang.python
import incubaid.herolib.installers.lang.rust
import incubaid.herolib.installers.net.mycelium_installer
import incubaid.herolib.installers.net.wireguard_installer
import incubaid.herolib.installers.sysadmintools.b2
import incubaid.herolib.installers.sysadmintools.garage_s3
import incubaid.herolib.installers.threefold.griddriver
import incubaid.herolib.installers.virt.cloudhypervisor
import incubaid.herolib.installers.virt.docker
import incubaid.herolib.installers.virt.herorunner
import incubaid.herolib.installers.virt.kubernetes_installer
import incubaid.herolib.installers.virt.lima
// import incubaid.herolib.installers.virt.myhypervisor
import incubaid.herolib.installers.virt.pacman
import incubaid.herolib.installers.virt.podman
import incubaid.herolib.installers.virt.youki
import incubaid.herolib.installers.web.bun
import incubaid.herolib.installers.web.tailwind
import incubaid.herolib.installers.web.tailwind4
import incubaid.herolib.installers.web.traefik
import incubaid.herolib.installers.web.zola
import incubaid.herolib.virt.hetznermanager
import incubaid.herolib.virt.kubernetes

pub fn run_all(args_ PlayArgs) ! {
	mut args := args_
	// println('DEBUG: the args is: @{args}')
	mut plbook := args.plbook or {
		playbook.new(text: args.heroscript, path: args.heroscript_path)!
	}

	erpnext.play(mut plbook)!
	giteaclient.play(mut plbook)!
	ipapi.play(mut plbook)!
	jina.play(mut plbook)!
	mailclient.play(mut plbook)!
	meilisearch.play(mut plbook)!
	mycelium.play(mut plbook)!
	mycelium_rpc.play(mut plbook)!
	openai.play(mut plbook)!
	postgresql_client.play(mut plbook)!
	qdrant.play(mut plbook)!
	rcloneclient.play(mut plbook)!
	runpod.play(mut plbook)!
	sendgrid.play(mut plbook)!
	vastai.play(mut plbook)!
	wireguard.play(mut plbook)!
	zerodb_client.play(mut plbook)!
	zinit.play(mut plbook)!
	heroprompt.play(mut plbook)!
	meilisearch_installer.play(mut plbook)!
	coredns.play(mut plbook)!
	gitea.play(mut plbook)!
	livekit.play(mut plbook)!
	zinit_installer.play(mut plbook)!
	cryptpad.play(mut plbook)!
	element_chat.play(mut plbook)!
	golang.play(mut plbook)!
	nodejs.play(mut plbook)!
	python.play(mut plbook)!
	rust.play(mut plbook)!
	mycelium_installer.play(mut plbook)!
	wireguard_installer.play(mut plbook)!
	b2.play(mut plbook)!
	garage_s3.play(mut plbook)!
	griddriver.play(mut plbook)!
	cloudhypervisor.play(mut plbook)!
	docker.play(mut plbook)!
	herorunner.play(mut plbook)!
	kubernetes_installer.play(mut plbook)!
	lima.play(mut plbook)!
	// myhypervisor.play(mut plbook)!
	pacman.play(mut plbook)!
	podman.play(mut plbook)!
	youki.play(mut plbook)!
	bun.play(mut plbook)!
	tailwind.play(mut plbook)!
	tailwind4.play(mut plbook)!
	traefik.play(mut plbook)!
	zola.play(mut plbook)!
	hetznermanager.play(mut plbook)!
	kubernetes.play(mut plbook)!
}
