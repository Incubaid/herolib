module core

import crypto.md5
import incubaid.herolib.ui.console

pub enum CollectionErrorCategory {
	circular_include
	missing_include
	include_syntax_error
	invalid_page_reference
	invalid_file_reference
	file_not_found
	invalid_collection
	general_error
	acl_denied // NEW: Access denied by ACL
}

pub struct CollectionError {
pub mut:
	category CollectionErrorCategory
	page_key string // Format: "collection:page" or just collection name
	message  string
	file     string // Optional: specific file path if relevant
}

// Generate MD5 hash for error deduplication
// Hash is based on category + page_key (or file if page_key is empty)
pub fn (e CollectionError) hash() string {
	mut hash_input := '${e.category}'

	if e.page_key != '' {
		hash_input += ':${e.page_key}'
	} else if e.file != '' {
		hash_input += ':${e.file}'
	}

	return md5.hexhash(hash_input)
}

// Get human-readable error message
pub fn (e CollectionError) str() string {
	mut location := ''
	if e.page_key != '' {
		location = ' [${e.page_key}]'
	} else if e.file != '' {
		location = ' [${e.file}]'
	}

	return '[${e.category}]${location}: ${e.message}'
}

// Get category as string
pub fn (e CollectionError) category_str() string {
	return match e.category {
		.circular_include { 'Circular Include' }
		.missing_include { 'Missing Include' }
		.include_syntax_error { 'Include Syntax Error' }
		.invalid_page_reference { 'Invalid Page Reference' }
		.invalid_file_reference { 'Invalid File Reference' }
		.file_not_found { 'File Not Found' }
		.invalid_collection { 'Invalid Collection' }
		.general_error { 'General Error' }
		.acl_denied { 'ACL Access Denied' }
	}
}
