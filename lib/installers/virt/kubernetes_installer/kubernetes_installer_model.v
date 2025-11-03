module kubernetes_installer

import incubaid.herolib.data.encoderhero

pub const version = '1.31.0'
const singleton = true
const default = true

// Kubernetes installer - handles kubectl installation
@[heap]
pub struct KubernetesInstaller {
pub mut:
	name string = 'default'
}

// your checking & initialization code if needed
fn obj_init(mycfg_ KubernetesInstaller) !KubernetesInstaller {
	mut mycfg := mycfg_
	return mycfg
}

// called before start if done
fn configure() ! {
	// No configuration needed for kubectl
}

/////////////NORMALLY NO NEED TO TOUCH

pub fn heroscript_dumps(obj KubernetesInstaller) !string {
	return encoderhero.encode[KubernetesInstaller](obj)!
}

pub fn heroscript_loads(heroscript string) !KubernetesInstaller {
	mut obj := encoderhero.decode[KubernetesInstaller](heroscript)!
	return obj
}
