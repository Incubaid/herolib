module generator

import freeflowuniverse.herolib.baobab.specification { ActorInterface }
import freeflowuniverse.herolib.core.code { CustomCode, VFile }

fn generate_openrpc_interface_files(interfaces []ActorInterface) (VFile, VFile) {
	http := ActorInterface.http in interfaces

	iface_file := VFile{
		name:  'interface_openrpc'
		items: [CustomCode{$tmpl('./templates/interface_openrpc.v.template')}]
	}
	iface_test_file := VFile{
		name:  'interface_openrpc_test'
		items: [CustomCode{$tmpl('./templates/interface_openrpc_test.v.template')}]
	}
	return iface_file, iface_test_file
}

fn generate_openapi_interface_files(interfaces []ActorInterface) (VFile, VFile) {
	http := ActorInterface.http in interfaces
	dollar := '$'
	iface_file := VFile{
		name:  'interface_openapi'
		items: [CustomCode{$tmpl('./templates/interface_openapi.v.template')}]
	}
	iface_test_file := VFile{
		name:  'interface_openapi_test'
		items: [CustomCode{$tmpl('./templates/interface_openapi_test.v.template')}]
	}
	return iface_file, iface_test_file
}

fn generate_http_interface_files(controllers []ActorInterface) (VFile, VFile) {
	dollar := '$'
	openapi := ActorInterface.openapi in controllers
	openrpc := ActorInterface.openrpc in controllers

	iface_file := VFile{
		name:  'interface_http'
		items: [CustomCode{$tmpl('./templates/interface_http.v.template')}]
	}
	iface_test_file := VFile{
		name:  'interface_http_test'
		items: [CustomCode{$tmpl('./templates/interface_http_test.v.template')}]
	}
	return iface_file, iface_test_file
}
