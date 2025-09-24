module site

import os
// Combined config structure

@[heap]
pub struct SiteConfig {
pub mut:
	name        string
	title       string = 'My Documentation Site' // General site title
	description string // General site description, can be used for meta if meta_description not set
	tagline     string
	favicon     string = 'img/favicon.png'
	image       string = 'img/tf_graph.png' // General site image, can be used for meta if meta_image not set
	copyright   string = 'someone'
	footer      Footer
	menu        Menu
	imports     []ImportItem

	// New fields for Docusaurus compatibility
	url      string // The main URL of the site (from !!site.config url:)
	base_url string // The base URL for Docusaurus (from !!site.config base_url:)
	url_home string // The home page path relative to base_url (from !!site.config url_home:)

	meta_title string // Specific title for SEO metadata (from !!site.config_meta title:)
	meta_image string // Specific image for SEO metadata (og:image) (from !!site.config_meta image:)

	build_dest     []BuildDest // Production build destinations (from !!site.build_dest)
	build_dest_dev []BuildDest // Development build destinations (from !!site.build_dest_dev)
}

// Footer config structures
pub struct FooterItem {
pub mut:
	label string
	to    string
	href  string
}

pub struct FooterLink {
pub mut:
	title string
	items []FooterItem
}

pub struct Footer {
pub mut:
	style string = 'dark'
	links []FooterLink
}

// menu config structures
pub struct MenuItem {
pub mut:
	href     string
	to       string
	label    string
	position string
}

pub struct Menu {
pub mut:
	title         string
	items         []MenuItem
	logo_alt      string @[json: 'logoAlt']
	logo_src      string @[json: 'logoSrc']
	logo_src_dark string @[json: 'logoSrcDark']
}

pub struct BuildDest {
pub mut:
	path     string
	ssh_name string
}

pub struct ImportItem {
pub mut:
	name    string // will normally be empty
	url     string // http git url can be to specific path
	path    string
	dest    string            // location in the docs folder of the place where we will build the documentation site e.g. docusaurus
	replace map[string]string // will replace ${NAME} in the imported content
	visible bool = true
}
