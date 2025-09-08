module openrpc

import json
import x.json2
import net.unix
import os
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.schemas.jsonrpc

const testdata_dir = os.join_path(os.dir(@FILE), 'testdata')
const openrpc_path = os.join_path(testdata_dir, 'openrpc.json')

pub fn test_new_unix_server() ! {
	mut spec := OpenRPC{}
	handler := Handler{
		specification: new(path: openrpc_path)
	}
	server := new_unix_server(handler)
}
