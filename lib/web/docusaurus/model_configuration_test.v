module docusaurus

import os
import incubaid.herolib.core.pathlib
import incubaid.herolib.core.base // For context and Redis, if test needs to manage it
import time

const test_heroscript_content = '!!site.config\n    name:"Kristof"\n    title:"Internet Geek"\n    tagline:"Internet Geek"\n    url:"https://friends.threefold.info"\n    url_home:"docs/"\n    base_url:"/kristof/"\n    favicon:"img/favicon.png"\n    image:"img/tf_graph.png"\n    copyright:"Kristof"\n\n!!site.config_meta\n    description:"ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet."\n    image:"https://threefold.info/kristof/img/tf_graph.png"\n    title:"ThreeFold Technology Vision"\n\n!!site.build_dest\n    ssh_name:"production"\n    path:"/root/hero/www/info/kristof"\n\n!!site.navbar\n    title:"Kristof = Chief Executive Geek"\n    logo_alt:"Kristof Logo"\n    logo_src:"img/logo.svg"\n    logo_src_dark:"img/logo.svg"\n\n!!site.navbar_item\n    label:"ThreeFold Technology"\n    href:"https://threefold.info/kristof/"\n    position:"right"\n\n!!site.navbar_item\n    label:"ThreeFold.io"\n    href:"https://threefold.io"\n    position:"right"\n\n!!site.footer\n    style:"dark"\n\n!!site.footer_item\n    title:"Docs"\n    label:"Introduction"\n    href:"/docs"\n\n!!site.footer_item\n    title:"Docs"\n    label:"TFGrid V4 Docs"\n    href:"https://docs.threefold.io/"\n\n!!site.footer_item\n    title:"Community"\n    label:"Telegram"\n    href:"https://t.me/threefold"\n\n!!site.footer_item\n    title:"Community"\n    label:"X"\n    href:"https://x.com/threefold_io"\n\n!!site.footer_item\n    title:"Links"\n    label:"ThreeFold.io"\n    href:"https://threefold.io"\n'

fn test_load_configuration_from_heroscript() ! {
	// Ensure context is initialized for Redis connection if siteconfig.new() needs it implicitly
	base.context()!

	temp_cfg_dir := os.join_path(os.temp_dir(), 'test_docusaurus_cfg_${time.ticks()}')
	os.mkdir_all(temp_cfg_dir)!
	defer {
		os.rmdir_all(temp_cfg_dir) or { eprintln('Error removing temp dir.') }
	}

	heroscript_path := os.join_path(temp_cfg_dir, 'config.heroscript')
	os.write_file(heroscript_path, test_heroscript_content)!

	config := load_configuration(temp_cfg_dir)!

	// Main assertions
	assert config.main.name == 'kristof' // texttools.name_fix converts to lowercase
	assert config.main.title == 'Internet Geek'
	assert config.main.tagline == 'Internet Geek'
	assert config.main.url == 'https://friends.threefold.info'
	assert config.main.url_home == 'docs/'
	assert config.main.base_url == '/kristof/'
	assert config.main.favicon == 'img/favicon.png'
	assert config.main.image == 'img/tf_graph.png'
	assert config.main.copyright == 'Kristof'

	// Metadata assertions
	assert config.main.metadata.title == 'ThreeFold Technology Vision'
	assert config.main.metadata.description == 'ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet.'
	assert config.main.metadata.image == 'https://threefold.info/kristof/img/tf_graph.png'

	// Build Dest assertions
	assert config.main.build_dest.len == 1
	assert config.main.build_dest[0] == '/root/hero/www/info/kristof'

	// Navbar assertions
	assert config.navbar.title == 'Kristof = Chief Executive Geek'
	assert config.navbar.logo.alt == 'Kristof Logo'
	assert config.navbar.logo.src == 'img/logo.svg'
	assert config.navbar.logo.src_dark == 'img/logo.svg'
	assert config.navbar.items.len == 2
	assert config.navbar.items[0].label == 'ThreeFold Technology'
	assert config.navbar.items[0].href == 'https://threefold.info/kristof/'
	assert config.navbar.items[0].position == 'right'
	assert config.navbar.items[1].label == 'ThreeFold.io'
	assert config.navbar.items[1].href == 'https://threefold.io'
	assert config.navbar.items[1].position == 'right'

	// Footer assertions
	assert config.footer.style == 'dark'
	assert config.footer.links.len == 3 // 'Docs', 'Community', 'Links'

	// Check 'Docs' footer links
	mut docs_link_found := false
	for link in config.footer.links {
		if link.title == 'Docs' {
			docs_link_found = true
			assert link.items.len == 2
			assert link.items[0].label == 'Introduction'
			assert link.items[0].href == '/docs'
			assert link.items[1].label == 'TFGrid V4 Docs'
			assert link.items[1].href == 'https://docs.threefold.io/'
			break
		}
	}
	assert docs_link_found

	// Check 'Community' footer links
	mut community_link_found := false
	for link in config.footer.links {
		if link.title == 'Community' {
			community_link_found = true
			assert link.items.len == 2
			assert link.items[0].label == 'Telegram'
			assert link.items[0].href == 'https://t.me/threefold'
			assert link.items[1].label == 'X'
			assert link.items[1].href == 'https://x.com/threefold_io'
			break
		}
	}
	assert community_link_found

	// Check 'Links' footer links
	mut links_link_found := false
	for link in config.footer.links {
		if link.title == 'Links' {
			links_link_found = true
			assert link.items.len == 1
			assert link.items[0].label == 'ThreeFold.io'
			assert link.items[0].href == 'https://threefold.io'
			break
		}
	}
	assert links_link_found

	println('test_load_configuration_from_heroscript passed successfully.')
}
