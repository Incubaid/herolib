module site

import freeflowuniverse.herolib.core.texttools

__global (
	websites map[string]&Site
)

@[params]
pub struct FactoryArgs {
pub mut:
	name string = 'default'
}

pub fn new(args FactoryArgs) !&Site {
	name := texttools.name_fix(args.name)

	websites[name] = &Site{
		siteconfig: SiteConfig{
			name: name
		}
	}
	return get(name: name)!
}

pub fn get(args FactoryArgs) !&Site {
	name := texttools.name_fix(args.name)
	mut sc := websites[name] or { return error('siteconfig with name "${name}" does not exist') }
	return sc
}

pub fn exists(args FactoryArgs) bool {
	name := texttools.name_fix(args.name)
	mut sc := websites[name] or { return false }
	return true
}

pub fn default() !&Site {
	if websites.len == 0 {
		return new(name: 'default')!
	}
	return get()!
}

// list returns all site names that have been created
pub fn list() []string {
	return websites.keys()
}
