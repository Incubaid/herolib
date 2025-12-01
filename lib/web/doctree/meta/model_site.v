module meta

@[heap]
pub struct Site {
pub mut:
	pages      map[string]Page // key: "collection:page_name"
	nav        SideBar       // Navigation sidebar configuration
	siteconfig SiteConfig      // Full site configuration	
}
