module openrpc
import freeflowuniverse.herolib.schemas.openrpc
import x.json2

// discover returns the OpenRPC specification for the HeroModels service
fn (mut server RPCServer) discover() !json2.Any {
	spec_json := $tmpl("openrpc.json")
	return openrpc.decode_json_any(spec_json)!
}