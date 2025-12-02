module meta

@[heap]
pub struct Site {
pub mut:
	doctree_path   string         // path to the export of the doctree site
	config         SiteConfig     // Full site configuration
	root           Category       // The root category containing all top-level items
	announcements  []Announcement // there can be more than 1 announcement
	imports        []ImportItem
	build_dest     []BuildDest // Production build destinations (from !!site.build_dest)
	build_dest_dev []BuildDest // Development build destinations (from !!site.build_dest_dev)
}

pub fn (mut self Site) page_get(src string) !&Page {
	return self.root.page_get(src)!
}

pub fn (mut self Site) link_get(href string) !&Link {
	return self.root.link_get(href)!
}

pub fn (mut self Site) category_get(path string) !&Category {
	return self.root.category_get(path)!
}

// sidebar returns the root category for building the sidebar navigation
pub fn (mut self Site) sidebar() !&Category {
	return &self.root
}
