module core

import incubaid.herolib.develop.gittools
import os
import incubaid.herolib.data.markdown.tools as markdowntools

// Validate all links in collection
fn (mut c Collection) find_links() ! {
	for _, mut page in c.pages {
		content := page.content(include: true)!
		page.links = page.find_links(content)! // will walk over links see if errors and add errors
	}
}

// Fix all links in collection (rewrite files)
fn (mut c Collection) fix_links() ! {
	for _, mut page in c.pages {
		// Read original content
		content := page.content()!

		// Fix links
		fixed_content := page.content_with_fixed_links()!

		// Write back if changed
		if fixed_content != content {
			mut p := page.path()!
			p.write(fixed_content)!
		}
	}	
}


pub fn (mut c Collection) title_descriptions() ! {
	for _, mut p in c.pages {			
		if p.title == '' {
			p.title = markdowntools.extract_title(p.content(include: true)!)
		}
		// TODO in future should do AI
		if p.description == '' {
			p.description = p.title
		}
	}
}


// Detect git repository URL for a collection
fn (mut c Collection) init_git_info() ! {
	mut current_path := c.path()!

	// Walk up directory tree to find .git
	mut git_repo := current_path.parent_find('.git') or {
		// No git repo found
		return
	}

	if git_repo.path == '' {
		panic('Unexpected empty git repo path')
	}

	mut gs := gittools.new()!
	mut p := c.path()!
	mut location := gs.gitlocation_from_path(p.path)!

	r := os.execute_opt('cd ${p.path} && git branch --show-current')!

	location.branch_or_tag = r.output.trim_space()

	c.git_url = location.web_url()!
}
