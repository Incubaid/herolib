module base

import freeflowuniverse.herolib.data.paramsparser

@[params]
pub struct ContextConfigArgs {
pub mut:
	id           u32
	name         string = 'default'
	params       string
	coderoot     string
	interactive  bool
	secret       string
	encrypt      bool
	priv_key_hex string // hex representation of private key
}

// configure a context object
// params: .
// ```
// id		   u32 //if not set then redis will get a new context id
// name        string = 'default'
// params      string
// coderoot    string
// interactive bool
// secret      string
// priv_key_hex string //hex representation of private key
// ```
pub fn context_new(args_ ContextConfigArgs) !&Context {
	mut args := ContextConfig{
		id:          args_.id
		name:        args_.name
		params:      args_.params
		coderoot:    args_.coderoot
		interactive: args_.interactive
	}

	mut c := Context{
		config: args
	}

	if args.params.len > 0 {
		mut p := paramsparser.new('')!
		c.params_ = &p
	}

	c.save()!
	contexts[args.id] = &c

	return contexts[args.id] or { panic('bug') }
}

pub fn context_get(id u32) !&Context {
	context_current = id

	if id in contexts {
		return contexts[id] or { panic('bug') }
	}

	mut mycontext := Context{
		config: ContextConfig{
			id: id
		}
	}

	if mycontext.cfg_redis_exists()! {
		mycontext.load()!
		return &mycontext
	}

	mut mycontext2 := context_new(id: id)!
	return mycontext2
}

pub fn context_select(id u32) !&Context {
	context_current = id
	return context()!
}

pub fn context() !&Context {
	return context_get(context_current)!
}
