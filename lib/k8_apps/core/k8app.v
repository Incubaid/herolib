module core

import incubaid.herolib.virt.kubernetes


pub struct K8App {
pub mut:
	kube_client kubernetes.KubeClient @[skip]
	namespace string
	hostname  string
	app_name string
	app_instance string
}

@[params]
pub struct K8AppArgs {
pub mut:
	namespace string = "default" //namespace where deployed
	app_instance string @[required]
	app_name string @[required] //e.g. cryptpad, nextcloud, etc
}

//get a k8 app instance as to be used in installers
pub fn k8app(args_ K8AppArgs)!K8App {
	mut args := args_

	args.namespace = name_fix(args.namespace) //im place we deployed
	args.app_name = name_fix(args.app_name)
	args.app_instance = name_fix(args.app_instance)

	mut app := K8App{
		namespace: args.namespace
		hostname:  texttools.name_fix("${args.namespace}_${args.app_name}-${args.app_instance}")
		app_name: args.app_name
		app_instance: args.app_instance
		kube_client: kubernetes.get(create: true)!
	}
	
	return app
}