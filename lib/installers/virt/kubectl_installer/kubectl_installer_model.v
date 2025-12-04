module kubectl_installer

import incubaid.herolib.data.encoderhero

// Default kubectl version (matches K3s default version for compatibility)
pub const version = 'v1.33.1'
const singleton = true
const default = true

// kubectl installer - handles kubectl CLI tool installation
@[heap]
pub struct KubectlInstaller {
pub mut:
	name string = 'default'
	// kubectl version to install
	kubectl_version string = version
}

// your checking & initialization code if needed
fn obj_init(mycfg_ KubectlInstaller) !KubectlInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// kubectl is a CLI tool, no configuration needed
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj KubectlInstaller) !string {
	return encoderhero.encode[KubectlInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !KubectlInstaller {
	mut obj := encoderhero.decode[KubectlInstaller](heroscript)!
	return obj
}
