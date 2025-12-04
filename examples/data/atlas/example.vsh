#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.doctree
import incubaid.herolib.core.pathlib
import incubaid.herolib.web.doctree_client
import os

// Example: DocTree Export and AtlasClient Usage

println('DocTree Export & Client Example')
println('============================================================')

// Setup test directory
test_dir := '/tmp/doctree_example'
export_dir := '/tmp/doctree_export'
os.rmdir_all(test_dir) or {}
os.rmdir_all(export_dir) or {}
os.mkdir_all(test_dir)!

// Create a collection with some content
col_path := '${test_dir}/docs'
os.mkdir_all(col_path)!

mut cfile := pathlib.get_file(path: '${col_path}/.collection', create: true)!
cfile.write('name:docs')!

mut page1 := pathlib.get_file(path: '${col_path}/intro.md', create: true)!
page1.write('# Introduction\n\nWelcome to the docs!')!

mut page2 := pathlib.get_file(path: '${col_path}/guide.md', create: true)!
page2.write('# Guide\n\n!!include docs:intro\n\nMore content here.')!

// Create and scan doctree
println('\n1. Creating DocTree and scanning...')
mut a := doctree.new(name: 'my_docs')!
a.scan(path: test_dir)!

println('   Found ${a.collections.len} collection(s)')

// Validate links
println('\n2. Validating links...')
a.validate_links()!

col := a.get_collection('docs')!
if col.has_errors() {
	println('   Errors found:')
	col.print_errors()
} else {
	println('   No errors found!')
}

// Export collections
println('\n3. Exporting collections to ${export_dir}...')
a.export(
	destination: export_dir
	include:     true  // Process includes during export
	redis:       false // Don't use Redis for this example
)!
println('   ✓ Export complete')

// Use AtlasClient to access exported content
println('\n4. Using AtlasClient to read exported content...')
mut client := doctree_client.new(export_dir: export_dir)!

// List collections
collections := client.list_collections()!
println('   Collections: ${collections}')

// List pages in docs collection
pages := client.list_pages('docs')!
println('   Pages in docs: ${pages}')

// Read page content
println('\n5. Reading page content via AtlasClient...')
intro_content := client.get_page_content('docs', 'intro')!
println('   intro.md content:')
println('   ${intro_content}')

guide_content := client.get_page_content('docs', 'guide')!
println('\n   guide.md content (with includes processed):')
println('   ${guide_content}')

// Get metadata
println('\n6. Accessing metadata...')
metadata := client.get_collection_metadata('docs')!
println('   Collection name: ${metadata.name}')
println('   Collection path: ${metadata.path}')
println('   Number of pages: ${metadata.pages.len}')

println('\n✓ Example completed successfully!')
println('\nExported files are in: ${export_dir}')
println('  - content/docs/intro.md')
println('  - content/docs/guide.md')
println('  - meta/docs.json')

// Cleanup (commented out so you can inspect the files)
// os.rmdir_all(test_dir) or {}
// os.rmdir_all(export_dir) or {}
