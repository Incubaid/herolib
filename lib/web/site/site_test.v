module site

import os

fn test_play_collections() ! {
	mypath := '${os.dir(@FILE)}/example'

	mut sc := new(mypath)!

	// Add assertions here based on the expected site config structure
	assert sc.name == 'depin'
	assert sc.description == 'ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet.'
	assert sc.tagline == 'Geo Aware Internet Platform'
	assert sc.favicon == 'img/favicon.png'
	assert sc.image == 'img/tf_graph.png'
	assert sc.copyright == 'ThreeFold'

	// Assertions for menu
	assert sc.menu.title == 'ThreeFold DePIN Tech'
	assert sc.menu.items.len == 3 // Based on the three !!site.menu_item entries
	assert sc.menu.items[0].label == 'ThreeFold.io'
	assert sc.menu.items[0].href == 'https://threefold.io'
	assert sc.menu.items[0].position == 'right'
	assert sc.menu.items[1].label == 'Mycelium Network'
	assert sc.menu.items[1].href == 'https://mycelium.threefold.io/'
	assert sc.menu.items[1].position == 'right'
	assert sc.menu.items[2].label == 'AI Box'
	assert sc.menu.items[2].href == 'https://aibox.threefold.io/'
	assert sc.menu.items[2].position == 'right'

	// Assertions for footer
	assert sc.footer.style == 'dark'
	assert sc.footer.links.len == 3 // Based on the three unique titles in !!site.footer_item
	assert sc.footer.links[0].title == 'Docs'
	assert sc.footer.links[0].items.len == 4
	assert sc.footer.links[1].title == 'Features'
	assert sc.footer.links[1].items.len == 4
	assert sc.footer.links[2].title == 'Web'
	assert sc.footer.links[2].items.len == 5

	// Assertions for collections
	assert sc.import_collections.len == 1 // Based on the !!site.collections entry
	assert sc.import_collections[0].url == 'https://github.com/example/external-docs'
	assert sc.import_collections[0].replace.len == 2
	assert sc.import_collections[0].replace['PROJECT_NAME'] == 'My Project'
	assert sc.import_collections[0].replace['VERSION'] == '1.0.0'
	assert sc.import_collections[0].visible == false // Default value

	// Assertions for pages
	assert sc.pages.len == 4 // Based on the four !!site.page entries in site.heroscript

	// Assertions for the first page (intro)
	assert sc.pages[0].name == 'intro'
	assert sc.pages[0].description == 'ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet.'
	assert sc.pages[0].title == '' // No title specified in site.heroscript
	assert sc.pages[0].draft == false // Default value
	assert sc.pages[0].folder == '' // Default value
	assert sc.pages[0].prio == 0 // Default value
	assert sc.pages[0].src == '' // No src specified
	assert sc.pages[0].content == '' // No content specified

	// Assertions for the second page (mycelium)
	assert sc.pages[1].name == 'mycelium'
	assert sc.pages[1].description == '...'
	assert sc.pages[1].title == 'Mycelium as Title'
	assert sc.pages[1].draft == true
	assert sc.pages[1].folder == '/specs/components'
	assert sc.pages[1].prio == 4
	assert sc.pages[1].src == '' // No src specified
	assert sc.pages[1].content == 'the page content itself, only for small pages'

	// Assertions for the third page (fungistor with .md)
	assert sc.pages[2].name == 'fungistor'
	assert sc.pages[2].description == '....'
	assert sc.pages[2].title == 'fungistor as Title'
	assert sc.pages[2].draft == false // Default value
	assert sc.pages[2].folder == '/specs/components'
	assert sc.pages[2].prio == 1
	assert sc.pages[2].src == 'mycollection:mycelium.md'
	assert sc.pages[2].content == '' // No content specified

	// Assertions for the fourth page (fungistor without .md)
	assert sc.pages[3].name == 'fungistor'
	assert sc.pages[3].description == '...'
	assert sc.pages[3].title == 'fungistor as Title'
	assert sc.pages[3].draft == false // Default value
	assert sc.pages[3].folder == '/specs/components'
	assert sc.pages[3].prio == 1
	assert sc.pages[3].src == 'mycollection:mycelium'
	assert sc.pages[3].content == '' // No content specified
}
