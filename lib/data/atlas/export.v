module atlas

import incubaid.herolib.core.pathlib

@[params]
pub struct ExportArgs {
pub mut:
    destination string
    reset       bool = true
    include     bool = true  // process includes during export
    redis       bool = true
}

// Generate edit URL for a page in the repository
pub fn (p Page) get_edit_url() !string {
	col := p.collection
	if col.git_url == '' {
		return error('No git URL available for collection ${col.name}')
	}

	// Remove .git suffix if present
	mut url := col.git_url
	if url.ends_with('.git') {
		url = url[0..url.len - 4]
	}

	// Determine the provider and build appropriate edit URL
	if url.contains('github.com') {
		return '${url}/edit/${col.git_branch}/${p.path.name()}'
	} else if url.contains('gitlab.com') {
		return '${url}/-/edit/${col.git_branch}/${p.path.name()}'
	} else if url.contains('gitea') || url.contains('git.') {
		// Gitea-like interfaces
		return '${url}/src/branch/${col.git_branch}/${p.path.name()}'
	}

	// Fallback: assume similar to GitHub
	return '${url}/edit/${col.git_branch}/${p.path.name()}'
}

// Export all collections
pub fn (mut a Atlas) export(args ExportArgs) ! {
    mut dest := pathlib.get_dir(path: args.destination, create: true)!

    if args.reset {
        dest.empty()!
    }

    // Validate links before export
    a.validate_links()!

    for _, mut col in a.collections {
        col.export(
            destination: dest
            reset:       args.reset
            include:     args.include
            redis:       args.redis
        )!

        // Print collection info including git URL
        if col.has_errors() {
            col.print_errors()
        }
        
        if col.git_url != '' {
            println('Collection ${col.name} source: ${col.git_url} (branch: ${col.git_branch})')
        }
    }
}