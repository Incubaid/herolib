module docusaurus

import incubaid.herolib.core.pathlib
// import incubaid.herolib.data.atlas.client as atlas_client
// import incubaid.herolib.web.site { Page, Section, Site }
import incubaid.herolib.data.markdown.tools as markdowntools
import incubaid.herolib.ui.console
import os

// Generate docs from site configuration
pub fn (mut docsite DocSite) link_docs() ! {
	c := config()!

	// we generate the docs in the build path
	docs_path := '${c.path_build.path}/docs'

	//reset it
	os.rmdir_all(docs_path)!
	os.mkdir(docs_path)!

	//TODO: now link all the collections to the docs folder

	println(c)

	if true{
		panic('link_docs is not yet implemented')
	}
	// $dbg;
}
