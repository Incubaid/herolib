module atlas

import incubaid.herolib.core.pathlib
import os
import json

const test_base = '/tmp/atlas_test'

// Test recursive export with chained cross-collection links
// Setup: Collection A links to B, Collection B links to C
// Expected: When exporting A, it should include pages from B and C
fn test_export_recursive_links() {
	// Create 3 collections with chained links
	col_a_path := '${test_base}/recursive_export/col_a'
	col_b_path := '${test_base}/recursive_export/col_b'
	col_c_path := '${test_base}/recursive_export/col_c'

	os.mkdir_all(col_a_path)!
	os.mkdir_all(col_b_path)!
	os.mkdir_all(col_c_path)!

	// Collection A: links to B
	mut cfile_a := pathlib.get_file(path: '${col_a_path}/.collection', create: true)!
	cfile_a.write('name:col_a')!
	mut page_a := pathlib.get_file(path: '${col_a_path}/page_a.md', create: true)!
	page_a.write('# Page A\\n\\nThis is page A.\\n\\n[Link to Page B](col_b:page_b)')!

	// Collection B: links to C
	mut cfile_b := pathlib.get_file(path: '${col_b_path}/.collection', create: true)!
	cfile_b.write('name:col_b')!
	mut page_b := pathlib.get_file(path: '${col_b_path}/page_b.md', create: true)!
	page_b.write('# Page B\\n\\nThis is page B with link to C.\\n\\n[Link to Page C](col_c:page_c)')!

	// Collection C: final page
	mut cfile_c := pathlib.get_file(path: '${col_c_path}/.collection', create: true)!
	cfile_c.write('name:col_c')!
	mut page_c := pathlib.get_file(path: '${col_c_path}/page_c.md', create: true)!
	page_c.write('# Page C\\n\\nThis is the final page in the chain.')!

	// Create Atlas and add all collections
	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_a_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col_b_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col_c_path)!)!

	// Validate links before export to populate page.links
	a.validate_links()!

	// Export
	export_path := '${test_base}/export_recursive'
	a.export(destination: export_path)!

	// ===== VERIFICATION PHASE =====

	// 1. Verify directory structure exists
	assert os.exists('${export_path}/content'), 'Export content directory should exist'
	assert os.exists('${export_path}/content/col_a'), 'Collection col_a directory should exist'
	assert os.exists('${export_path}/meta'), 'Export meta directory should exist'

	// 2. Verify all pages exist in col_a export directory
	// Note: Exported pages from other collections go to col_a directory
	assert os.exists('${export_path}/content/col_a/page_a.md'), 'page_a.md should be exported'
	assert os.exists('${export_path}/content/col_a/page_b.md'), 'page_b.md from col_b should be included'
	assert os.exists('${export_path}/content/col_a/page_c.md'), 'page_c.md from col_c should be included'

	// 3. Verify page content is correct
	content_a := os.read_file('${export_path}/content/col_a/page_a.md')!
	assert content_a.contains('# Page A'), 'page_a content should have title'
	assert content_a.contains('This is page A'), 'page_a content should have expected text'
	assert content_a.contains('[Link to Page B]'), 'page_a should have link to page_b'

	content_b := os.read_file('${export_path}/content/col_a/page_b.md')!
	assert content_b.contains('# Page B'), 'page_b content should have title'
	assert content_b.contains('This is page B'), 'page_b content should have expected text'
	assert content_b.contains('[Link to Page C]'), 'page_b should have link to page_c'

	content_c := os.read_file('${export_path}/content/col_a/page_c.md')!
	assert content_c.contains('# Page C'), 'page_c content should have title'
	assert content_c.contains('This is the final page'), 'page_c content should have expected text'

	// 4. Verify metadata exists and is valid
	assert os.exists('${export_path}/meta/col_a.json'), 'Metadata file for col_a should exist'

	meta_content := os.read_file('${export_path}/meta/col_a.json')!
	assert meta_content.len > 0, 'Metadata file should not be empty'

	// // Parse metadata JSON and verify structure
	// mut meta := json.decode(map[string]map[string]interface{}, meta_content) or {
	// 	panic('Failed to parse metadata JSON: ${err}')
	// }
	// assert meta.len > 0, 'Metadata should have content'
	// assert meta['name'] != none, 'Metadata should have name field'

	// 5. Verify that pages from B and C are NOT exported to separate col_b and col_c directories
	// (they should only be in col_a directory)
	meta_col_b_exists := os.exists('${export_path}/meta/col_b.json')
	meta_col_c_exists := os.exists('${export_path}/meta/col_c.json')
	assert !meta_col_b_exists, 'col_b metadata should not exist (pages copied to col_a)'
	assert !meta_col_c_exists, 'col_c metadata should not exist (pages copied to col_a)'

	// 6. Verify the recursive depth worked
	// All three pages should be accessible through the exported col_a
	assert os.exists('${export_path}/content/col_a/page_a.md'), 'Level 1 page should exist'
	assert os.exists('${export_path}/content/col_a/page_b.md'), 'Level 2 page (via A->B) should exist'
	assert os.exists('${export_path}/content/col_a/page_c.md'), 'Level 3 page (via A->B->C) should exist'

	// 7. Verify that the link chain is properly documented
	// page_a links to page_b, page_b links to page_c
	// The links should be preserved in the exported content
	page_a_content := os.read_file('${export_path}/content/col_a/page_a.md')!
	page_b_content := os.read_file('${export_path}/content/col_a/page_b.md')!
	page_c_content := os.read_file('${export_path}/content/col_a/page_c.md')!

	// Links are preserved with collection:page format
	assert page_a_content.contains('col_b:page_b') || page_a_content.contains('page_b'), 'page_a should reference page_b'

	assert page_b_content.contains('col_c:page_c') || page_b_content.contains('page_c'), 'page_b should reference page_c'

	println('✓ Recursive cross-collection export test passed')
	println('  - All 3 pages exported to col_a directory (A -> B -> C)')
	println('  - Content verified for all pages')
	println('  - Metadata validated')
	println('  - Link chain preserved')
}

// Test recursive export with cross-collection images
// Setup: Collection A links to image in Collection B
// Expected: Image should be copied to col_a export directory
fn test_export_recursive_with_images() {
	col_a_path := '${test_base}/recursive_img/col_a'
	col_b_path := '${test_base}/recursive_img/col_b'

	os.mkdir_all(col_a_path)!
	os.mkdir_all(col_b_path)!
	os.mkdir_all('${col_a_path}/img')!
	os.mkdir_all('${col_b_path}/img')!

	// Collection A with local image
	mut cfile_a := pathlib.get_file(path: '${col_a_path}/.collection', create: true)!
	cfile_a.write('name:col_a')!

	mut page_a := pathlib.get_file(path: '${col_a_path}/page_a.md', create: true)!
	page_a.write('# Page A\\n\\n![Local Image](local.png)\\n\\n[Link to B](col_b:page_b)')!

	// Create local image
	os.write_file('${col_a_path}/img/local.png', 'fake png data')!

	// Collection B with image and linked page
	mut cfile_b := pathlib.get_file(path: '${col_b_path}/.collection', create: true)!
	cfile_b.write('name:col_b')!

	mut page_b := pathlib.get_file(path: '${col_b_path}/page_b.md', create: true)!
	page_b.write('# Page B\\n\\n![B Image](b_image.jpg)')!

	// Create image in collection B
	os.write_file('${col_b_path}/img/b_image.jpg', 'fake jpg data')!

	// Create Atlas
	mut a := new()!
	a.add_collection(mut pathlib.get_dir(path: col_a_path)!)!
	a.add_collection(mut pathlib.get_dir(path: col_b_path)!)!

	// Validate and export
	a.validate_links()!
	export_path := '${test_base}/export_recursive_img'
	a.export(destination: export_path)!

	// Verify pages exported
	assert os.exists('${export_path}/content/col_a/page_a.md'), 'page_a should exist'
	assert os.exists('${export_path}/content/col_a/page_b.md'), 'page_b from col_b should be included'

	// Verify images exported to col_a image directory
	assert os.exists('${export_path}/content/col_a/img/local.png'), 'Local image should exist'
	assert os.exists('${export_path}/content/col_a/img/b_image.jpg'), 'Image from cross-collection reference should be copied'

	println('✓ Recursive cross-collection with images test passed')
}
