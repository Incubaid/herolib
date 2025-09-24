## how to remember clients, installers as a global

the following is a good pragmatic way to remember clients, installers as a global, use it as best practice.

```vmodule docsite

module docsite

import freeflowuniverse.herolib.core.texttools

__global (
	siteconfigs  map[string]&SiteConfig
)

@[params]
pub struct FactoryArgs {
pub mut:
	name string = "default"
}

pub fn new(args FactoryArgs) !&SiteConfig {
	name := texttools.name_fix(args.name)
	siteconfigs[name] = &SiteConfig{
		name: name
	}
	return get(name:name)!
}

pub fn get(args FactoryArgs) !&SiteConfig {
	name := texttools.name_fix(args.name)
	mut sc := siteconfigs[name] or {
		return error('siteconfig with name "${name}" does not exist')
	}
	return sc
}

pub fn default() !&SiteConfig {
	if siteconfigs.len == 0 {
		return new(name:'default')!
	}
	return get()!
}

```