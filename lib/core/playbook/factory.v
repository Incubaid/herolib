module playbook

import incubaid.herolib.core.base

@[params]
pub struct PlayBookNewArgs {
pub mut:
	path       string
	text       string
	prio       int = 50
	priorities map[int]string // filter and give priority, see filtersort method to know how to use
	replace    map[string]string
}

// get a new plbook from a local path or text
pub fn new(args_ PlayBookNewArgs) !PlayBook {
	mut args := args_

	mut c := base.context() or { return error('failed to get context: ${err}') }

	mut s := c.session_new()!

	mut plbook := PlayBook{
		session: &s
	}
	if args.path.len > 0 || args.text.len > 0 {
		plbook.add(
			path:    args.path
			text:    args.text
			prio:    args.prio
			replace: args.replace
		)!
	}

	if args.priorities.len > 0 {
		plbook.filtersort(priorities: args.priorities)!
	}

	return plbook
}
