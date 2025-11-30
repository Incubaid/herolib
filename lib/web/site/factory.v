module site

import incubaid.herolib.core.texttools

__global (
	mywebsites map[string]&Site
)

@[params]
pub struct FactoryArgs {
pub mut:
	name string = 'default'
}

pub fn new(args FactoryArgs) !&Site {
	name := texttools.name_fix(args.name)

	// Check if a site with this name already exists
	if name in mywebsites {
		// Return the existing site instead of creating a new one
		return get(name: name)!
	}

	mywebsites[name] = &Site{
		siteconfig: SiteConfig{
			name: name
		}
	}
	return get(name: name)!
}

pub fn get(args FactoryArgs) !&Site {
	name := texttools.name_fix(args.name)
	mut sc := mywebsites[name] or { return error('siteconfig with name "${name}" does not exist') }
	return sc
}

pub fn exists(args FactoryArgs) bool {
	name := texttools.name_fix(args.name)
	return name in mywebsites
}

pub fn default() !&Site {
	if mywebsites.len == 0 {
		return new(name: 'default')!
	}
	return get()!
}

// list returns all site names that have been created
pub fn list() []string {
	return mywebsites.keys()
}
