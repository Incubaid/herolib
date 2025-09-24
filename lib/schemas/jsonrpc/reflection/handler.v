module reflection

import freeflowuniverse.herolib.schemas.jsonrpc

pub struct Handler[T] {
pub mut:
	receiver T
}

pub fn new_handler[T](receiver T) Handler[T] {
	return Handler[T]{
		receiver: receiver
	}
}

pub fn (mut h Handler[T]) handle(request jsonrpc.Request) !jsonrpc.Response {
	receiver := h.receiver
	$for method in receiver.methods {
		println('method ${method}')
	}
}
