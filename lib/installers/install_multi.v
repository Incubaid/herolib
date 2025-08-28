module installers

import freeflowuniverse.herolib.installers.base
// import freeflowuniverse.herolib.installers.develapps.vscode
// import freeflowuniverse.herolib.installers.develapps.chrome
// import freeflowuniverse.herolib.installers.virt.podman as podman_installer
// import freeflowuniverse.herolib.installers.virt.buildah as buildah_installer
// import freeflowuniverse.herolib.installers.virt.lima
// import freeflowuniverse.herolib.installers.net.mycelium
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.installers.lang.rust
import freeflowuniverse.herolib.installers.lang.golang
import freeflowuniverse.herolib.installers.lang.vlang
import freeflowuniverse.herolib.installers.lang.herolib
import freeflowuniverse.herolib.installers.lang.nodejs
import freeflowuniverse.herolib.installers.lang.python
// import freeflowuniverse.herolib.installers.web.zola
// import freeflowuniverse.herolib.installers.web.tailwind
// import freeflowuniverse.herolib.installers.hero.heroweb
// import freeflowuniverse.herolib.installers.hero.herodev
// import freeflowuniverse.herolib.installers.sysadmintools.daguserver
import freeflowuniverse.herolib.installers.sysadmintools.rclone
// import freeflowuniverse.herolib.installers.sysadmintools.prometheus
// import freeflowuniverse.herolib.installers.sysadmintools.grafana
// import freeflowuniverse.herolib.installers.sysadmintools.fungistor
// import freeflowuniverse.herolib.installers.sysadmintools.garage_s3
import freeflowuniverse.herolib.installers.infra.zinit_installer

@[params]
pub struct InstallArgs {
pub mut:
	names     string
	reset     bool
	uninstall bool
	gitpull   bool
	gitreset  bool
	start     bool
}

pub fn names(args_ InstallArgs) []string {
	names := '
		base
		caddy
		chrome
		hero
		dagu
		develop
		fungistor
		garage_s3
		golang
		grafana
		hero
		herodev
		// heroweb
		lima
		mycelium
		nodejs
		herocontainers
		prometheus
		rclone
		rust
		tailwind
		vlang
		vscode
		zinit
		zola
		'
	mut ns := texttools.to_array(names)
	ns.sort()
	return ns
}

pub fn install_multi(args_ InstallArgs) ! {
	mut args := args_
	mut items := []string{}
	for item in args.names.split(',').map(it.trim_space()) {
		if item !in items {
			items << item
		}
	}
	for item in items {
		match item {
			'base' {
				base.install(reset: args.reset)!
			}
			'develop' {
				base.install(reset: args.reset, develop: true)!
			}
			'rclone' {
				// rclone.install(reset: args.reset)!
				mut rc := rclone.get()!
				rc.install(reset: args.reset)!
			}
			'rust' {
				mut i := rust.get()!
				i.install(reset: args.reset)!
			}
			'golang' {
				mut g := golang.get()!
				g.install(reset: args.reset)!
			}
			'vlang' {
				vlang.install(reset: args.reset)!
			}
			'hero' {
				herolib.install(
					reset:     args.reset
				)!
			}
			// 'hero' {
			// 	herolib.hero_install(reset: args.reset)!
			// }
			// 'caddy' {
			// caddy.install(reset: args.reset)!
			// caddy.configure_examples()!
			// }
			// 'chrome' {
			// 	chrome.install(reset: args.reset, uninstall: args.uninstall)!
			// }
			// 'mycelium' {
			// 	mycelium.install(reset: args.reset)!
			// 	mycelium.start()!
			// }
			// 'garage_s3' {
			// 	mut garages3 := garage_s3.get()!
			// 	garages3.install(reset: args.reset)!
			// }
			// 'fungistor' {
			// 	fungistor.install(reset: args.reset)!
			// }
			// 'lima' {
			// 	lima.install_(reset: args.reset, uninstall: args.uninstall)!
			// }
			// 'herocontainers' {
			// 	mut podman_installer0 := podman_installer.get()!
			// 	mut buildah_installer0 := buildah_installer.get()!
			// 	if args.reset {
			// 		podman_installer0.destroy()! // will remove all
			// 		buildah_installer0.destroy()! // will remove all
			// 	}
			// 	podman_installer0.install()!
			// 	buildah_installer0.install()!
			// }
			// 'prometheus' {
			// 	prometheus.install(reset: args.reset)!
			// }
			// 'grafana' {
			// 	grafana.install(reset: args.reset)!
			// }
			// 'vscode' {
			// 	vscode.install(reset: args.reset)!
			// }
			'nodejs' {
				mut i := nodejs.get()!
				i.install(reset: args.reset)!
			}
			'python' {
				mut i := python.get()!
				i.install()!
			}
			// 'herodev' {
			// herodev.install()!
			// }
			// 'heroweb' {
			// heroweb.install()!
			// }
			// 'dagu' {
			// 	// will call the installer underneith
			// 	mut dserver := daguserver.get()!
			// 	dserver.install()!
			// 	dserver.restart()!
			// 	// mut dagucl:=dserver.client()!
			// }
			// 'zola' {
			// 	mut i2 := zola.get()!
			// 	i2.install()! // will also install tailwind
			// }
			// 'tailwind' {
			// 	mut i := tailwind.get()!
			// 	i.install()!
			// }
			'zinit' {
				mut i := zinit_installer.get()!
				i.install()!
			}
			else {
				return error('cannot find installer for: ${item}')
			}
		}
	}
}
