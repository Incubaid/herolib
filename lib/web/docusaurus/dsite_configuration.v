module docusaurus

import incubaid.herolib.web.site

// IS THE ONE AS USED BY DOCUSAURUS

pub struct Configuration {
pub mut:
	main             Main
	navbar           Navbar
	footer           Footer
	sidebar_json_txt string // will hold the sidebar.json content
	announcement     AnnouncementBar
}

pub struct Main {
pub mut:
	title          string
	tagline        string
	favicon        string
	url            string
	base_url       string @[json: 'baseUrl']
	url_home       string
	image          string
	metadata       Metadata
	build_dest     []string @[json: 'buildDest']
	build_dest_dev []string @[json: 'buildDestDev']
	copyright      string
	name           string
}

pub struct Metadata {
pub mut:
	description string
	image       string
	title       string
}

pub struct Navbar {
pub mut:
	title string
	logo  Logo
	items []NavbarItem
}

pub struct Logo {
pub mut:
	alt      string
	src      string
	src_dark string @[json: 'srcDark']
}

pub struct NavbarItem {
pub mut:
	label    string
	href     string @[omitempty]
	position string
	to       string @[omitempty]
}

pub struct Footer {
pub mut:
	style string
	links []FooterLink
}

pub struct FooterLink {
pub mut:
	title string
	items []FooterItem
}

pub struct FooterItem {
pub mut:
	label string
	href  string @[omitempty]
	to    string @[omitempty]
}

pub struct AnnouncementBar {
pub mut:
	// id               string @[json: 'id']
	content          string @[json: 'content']
	background_color string @[json: 'backgroundColor']
	text_color       string @[json: 'textColor']
	is_closeable     bool   @[json: 'isCloseable']
}

// This function is a pure transformer: site.SiteConfig -> docusaurus.Configuration
fn new_configuration(mysite site.Site) !Configuration {
	// Transform site.SiteConfig to docusaurus.Configuration
	mut site_cfg := mysite.siteconfig
	mut nav_items := []NavbarItem{}
	for item in site_cfg.menu.items {
		nav_items << NavbarItem{
			label:    item.label
			href:     item.href
			position: item.position
			to:       item.to
		}
	}

	mut footer_links := []FooterLink{}
	for link in site_cfg.footer.links {
		mut footer_items_mapped := []FooterItem{}
		for item in link.items {
			footer_items_mapped << FooterItem{
				label: item.label
				href:  item.href
				to:    item.to
			}
		}
		footer_links << FooterLink{
			title: link.title
			items: footer_items_mapped
		}
	}

	sidebar_json_txt := mysite.nav.sidebar_to_json()!

	cfg := Configuration{
		main:             Main{
			title:          site_cfg.title
			tagline:        site_cfg.tagline
			favicon:        site_cfg.favicon
			url:            site_cfg.url
			base_url:       site_cfg.base_url
			url_home:       site_cfg.url_home
			image:          site_cfg.image
			metadata:       Metadata{
				title:       if site_cfg.meta_title == '' {
					site_cfg.title
				} else {
					site_cfg.meta_title
				}
				description: if site_cfg.description == '' {
					site_cfg.tagline
				} else {
					site_cfg.description
				}
				image:       if site_cfg.meta_image == '' {
					site_cfg.image
				} else {
					site_cfg.meta_image
				}
			}
			build_dest:     site_cfg.build_dest.map(it.path)
			build_dest_dev: site_cfg.build_dest_dev.map(it.path)
			copyright:      site_cfg.copyright
			name:           site_cfg.name
		}
		navbar:           Navbar{
			title: site_cfg.menu.title
			logo:  Logo{
				alt:      site_cfg.menu.logo_alt
				src:      site_cfg.menu.logo_src
				src_dark: site_cfg.menu.logo_src_dark
			}
			items: nav_items
		}
		footer:           Footer{
			style: site_cfg.footer.style
			links: footer_links
		}
		announcement:     AnnouncementBar{
			// id:               site_cfg.announcement.id
			content:          site_cfg.announcement.content
			background_color: site_cfg.announcement.background_color
			text_color:       site_cfg.announcement.text_color
			is_closeable:     site_cfg.announcement.is_closeable
		}
		sidebar_json_txt: sidebar_json_txt
	}

	return config_fix(cfg)!
}

fn config_fix(config Configuration) !Configuration {
	// Fix empty logo sources by providing defaults if all fields are empty
	mut navbar_fixed := config.navbar
	if config.navbar.logo.src == '' && config.navbar.logo.src_dark == ''
		&& config.navbar.logo.alt == '' {
		// Provide default logo values when all are empty
		navbar_fixed = Navbar{
			title: config.navbar.title
			logo:  Logo{
				alt:      'Logo'
				src:      'img/logo.svg'
				src_dark: 'img/logo_dark.svg'
			}
			items: config.navbar.items
		}
	}

	return Configuration{
		...config
		main:   Main{
			...config.main
			title:    if config.main.title == '' { 'Docusaurus' } else { config.main.title }
			favicon:  if config.main.favicon == '' { 'img/favicon.ico' } else { config.main.favicon }
			url:      if config.main.url == '' { 'https://example.com' } else { config.main.url }
			base_url: if config.main.base_url == '' { '/' } else { config.main.base_url }
			metadata: Metadata{
				...config.main.metadata
				description: if config.main.metadata.description == '' {
					'Documentation built with Docusaurus.'
				} else {
					config.main.metadata.description
				}
				title:       if config.main.metadata.title == '' {
					config.main.title
				} else {
					config.main.metadata.title
				}
			}
		}
		navbar: navbar_fixed
	}
}
