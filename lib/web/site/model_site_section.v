module site

@[heap]
pub struct Site {
pub mut:
	pages      []Page
	sections   []Section
	siteconfig SiteConfig
}

pub struct Section {
pub mut:
	name        string
	position    int
	path        string
	label       string
	description string
}
