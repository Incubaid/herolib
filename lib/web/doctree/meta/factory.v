module meta

import incubaid.herolib.core.texttools

__global (
	sites_global map[string]&Site
)

@[params]
pub struct FactoryArgs {
pub mut:
	name string = 'default'
}

pub fn new(args FactoryArgs) !&Site {
	name := texttools.name_fix(args.name)

	// Check if a site with this name already exists
	if name in sites_global {
		// Return the existing site instead of creating a new one
		return get(name: name)!
	}

	mut site := Site{
		config: SiteConfig{
			name: name
		}
		root: Category{}
	}
	sites_global[name] = &site
	return get(name: name)!
}

pub fn get(args FactoryArgs) !&Site {
	name := texttools.name_fix(args.name)
	// mut sc := sites_global[name] or { return error('siteconfig with name "${name}" does not exist') }
	return sites_global[name] or {
		print_backtrace()
		return error('could not get site with name:${name}')
	}
}

pub fn exists(args FactoryArgs) bool {
	name := texttools.name_fix(args.name)
	return name in sites_global
}

pub fn reset() {
	sites_global.clear()
}

pub fn default() !&Site {
	if sites_global.len == 0 {
		return new(name: 'default')!
	}
	return get()!
}

// list returns all site names that have been created
pub fn list() []string {
	return sites_global.keys()
}
