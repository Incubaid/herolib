#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.atlas
import incubaid.herolib.core.pathlib
import os

// Example: Save and Load Atlas Collections

println('Atlas Save/Load Example')
println('============================================================')

// Setup test directory
test_dir := '/tmp/atlas_example'
os.rmdir_all(test_dir) or {}
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

// Create and scan atlas
println('\n1. Creating Atlas and scanning...')
mut a := atlas.new(name: 'my_docs')!
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

// Save all collections
println('\n3. Saving collections to .collection.json...')
a.save_all()!
println('   Saved to ${col_path}/.collection.json')

// Load in a new atlas
println('\n4. Loading collections in new Atlas...')
mut a2 := atlas.new(name: 'loaded_docs')!
a2.load_from_directory(test_dir)!

println('   Loaded ${a2.collections.len} collection(s)')

// Access loaded data
println('\n5. Accessing loaded data...')
loaded_col := a2.get_collection('docs')!
println('   Collection: ${loaded_col.name}')
println('   Pages: ${loaded_col.pages.len}')

for name, page in loaded_col.pages {
	println('     - ${name}: ${page.path.path}')
}

// Read page content
println('\n6. Reading page content...')
mut intro_page := loaded_col.page_get('intro')!
content := intro_page.read_content()!
println('   intro.md content:')
println('   ${content}')

println('\n✓ Example completed successfully!')
println('\nNow you can use the Python loader:')
println('  python3 lib/data/atlas/atlas_loader.py')

// Cleanup
os.rmdir_all(test_dir) or {}
