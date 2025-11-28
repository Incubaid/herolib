module site

@[heap]
pub struct Site {
pub mut:
	pages      map[string]Page // key: "collection:page_name"
	nav        NavConfig       // Navigation sidebar configuration
	siteconfig SiteConfig      // Full site configuration
}
