module core

import incubaid.herolib.virt.kubernetes


pub struct K8App {
pub mut:
	kube_client kubernetes.KubeClient @[skip]
	namespace string
	hostname  string

}

@[params]
pub struct K8AppArgs {
pub mut:
	namespace @[required] 
	instance @[required]
	installername @[required]
	namespace string
	hostname  string
}

//get a k8 app instance as to be used in installers
pub fn k8app(args_ K8AppArgs)!K8App {
	mut args := args_

	args.instance = name_fix(args.instance)
	args.namespace = name_fix(args.namespace)
	args.installername = name_fix(args.installername)

	mut app := K8App{
		namespace: args.namespace
		hostname:  texttools.name_fix("${args.installername}-${args.instance}")
		kube_client: kubernetes.get(create: true)!
	}
	
	return app
}