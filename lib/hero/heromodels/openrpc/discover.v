module openrpc

import x.json2

// discover returns the OpenRPC specification for the HeroModels service
fn (mut server RPCServer) discover() !string {
	spec_json := $tmpl("openrpc.json")
	return spec_json
}