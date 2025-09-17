module heroserver

import freeflowuniverse.herolib.schemas.openrpc

// DocSpec is the main object passed to the documentation template.
pub struct DocSpec {
pub mut:
	info          openrpc.Info
	methods       []DocMethod
	objects       map[string]DocObject
}

// DocObject represents a logical grouping of methods.
pub struct DocObject {
pub mut:
	name        string
	description string
	methods     []DocMethod
}


// DocMethod holds the information for a single method to be displayed.
pub struct DocMethod {
pub mut:
	name			string
	summary			string
	description		string
	params			[]openrpc.ContentDescriptorRef
	result			openrpc.ContentDescriptorRef
	example_call	string
	example_response string
}
