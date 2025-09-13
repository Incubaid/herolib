module openrpc

import freeflowuniverse.herolib.schemas.openrpc
import freeflowuniverse.herolib.hero.heromodels

// new_heromodels_server creates a new HeroModels RPC server
pub fn test_new_heromodels_handler() ! {
	handler := new_heromodels_handler()!
}