module atlas

import incubaid.herolib.core.pathlib
import incubaid.herolib.develop.gittools

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
	mut gs := gittools.new()!
	mut location := gs.gitlocation_from_url(col.git_url)!
	location.branch_or_tag = col.git_branch
	location.path = p.path.name()

	// Determine the provider and build appropriate edit URL
	provider := location.provider
	mut url_base := 'https://${provider}.com/${location.account}/${location.name}'
	if provider.contains('gitea') || provider.contains('git.') {
		return '${url_base}/src/branch/${location.branch_or_tag}/${location.path}'
	}
	if provider == 'github' {
		return '${url_base}/edit/${location.branch_or_tag}/${location.path}'
	}
	if provider == 'gitlab' {
		return '${url_base}/-/edit/${location.branch_or_tag}/${location.path}'
	}

	// Fallback for unknown providers
	return '${url_base}/edit/${location.branch_or_tag}/${location.path}'
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