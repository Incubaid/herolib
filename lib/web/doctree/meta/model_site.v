module meta

@[heap]
pub struct Site {
pub mut:
	doctree_path   string     // path to the export of the doctree site
	config         SiteConfig // Full site configuration	
	pages          []Page
	links          []Link
	categories     []Category
	announcements  []Announcement // there can be more than 1 announcement
	imports        []ImportItem
	build_dest     []BuildDest // Production build destinations (from !!site.build_dest)
	build_dest_dev []BuildDest // Development build destinations (from !!site.build_dest_dev)
}

pub fn (mut s Site) sidebar() SideBar {
	// TODO: implement, use all info abouve []page, []categories, []links to build the sidebar
	return SideBar{}
}
