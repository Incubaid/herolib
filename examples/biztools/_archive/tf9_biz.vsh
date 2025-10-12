#!/usr/bin/env -S v -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

// #!/usr/bin/env -S v -cg -enable-globals run
import incubaid.herolib.data.doctree
import incubaid.herolib.ui.console
import incubaid.herolib.biz.bizmodel
import incubaid.herolib.core.playbook
import incubaid.herolib.core.playcmds
import incubaid.herolib.web.mdbook
import incubaid.herolib.biz.spreadsheet
import os

const name = 'tf9_budget'

const wikipath = '${os.home_dir()}/code/git.threefold.info/ourworld_holding/info_ourworld/collections/${name}'
const summarypath = '${wikipath}/summary.md'

// mut sh := spreadsheet.sheet_new(name: 'test2') or { panic(err) }
// println(sh)
// sh.row_new(descr: 'this is a description', name: 'something', growth: '0:100aed,55:1000eur')!
// println(sh)
// println(sh.wiki()!)

// exit(0)

// execute the actions so we have the info populated
// mut plb:=playbook.new(path: wikipath)!
// playcmds.run(mut plb,false)!

buildpath := '${os.home_dir()}/hero/var/mdbuild/bizmodel'

// just run the doctree & mdbook and it should
// load the doctree, these are all collections
mut tree := doctree.new(name: name)!
tree.scan(path: wikipath)!
tree.export(dest: buildpath, reset: true)!

// mut bm:=bizmodel.get("test")!
// println(bm)

mut mdbooks := mdbook.get()!
mdbooks.generate(
	name:         'bizmodel'
	summary_path: summarypath
	doctree_path: buildpath
	title:        'bizmodel ${name}'
)!
mdbook.book_open('bizmodel')!
