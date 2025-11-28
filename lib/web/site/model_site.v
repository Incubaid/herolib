module site

@[heap]
pub struct Site {
pub mut:
	pages      map[string]Page // key: is the id of the page
	nav 	   NavConfig //navigation of the site
	siteconfig SiteConfig
}
