module webdav

import encoding.xml
import log
import incubaid.herolib.core.pathlib
import incubaid.herolib.vfs
import incubaid.herolib.vfs.vfs_db
import os
import time
import net.http
import veb

// PropfindRequest represents a parsed PROPFIND request
pub struct PropfindRequest {
pub:
	typ         PropfindType
	props       []string // Property names if typ is prop
	depth       Depth    // Depth of the request (0, 1, or -1 for infinity)
	xml_content string   // Original XML content
}

pub enum Depth {
	infinity = -1
	zero     = 0
	one      = 1
}

// PropfindType represents the type of PROPFIND request
pub enum PropfindType {
	allprop  // Request all properties
	propname // Request property names only
	prop     // Request specific properties
	invalid  // Invalid request
}

// parse_propfind_xml parses the XML body of a PROPFIND request
pub fn parse_propfind_xml(req http.Request) !PropfindRequest {
	data := req.data
	// Parse Depth header
	depth_str := req.header.get_custom('Depth') or { '0' }
	depth := parse_depth(depth_str)

	if data.len == 0 {
		// If no body is provided, default to allprop
		return PropfindRequest{
			typ:         .allprop
			depth:       depth
			xml_content: ''
		}
	}

	doc := xml.XMLDocument.from_string(data) or { return error('Failed to parse XML: ${err}') }

	root := doc.root
	if root.name.to_lower() != 'propfind' && !root.name.ends_with(':propfind') {
		return error('Invalid PROPFIND request: root element must be propfind')
	}

	mut typ := PropfindType.allprop
	mut props := []string{}

	// Check for allprop, propname, or prop elements
	for child in root.children {
		if child is xml.XMLNode {
			node := child as xml.XMLNode

			// Check for allprop
			if node.name == 'allprop' || node.name == 'D:allprop' {
				typ = .allprop
				break
			}

			// Check for propname
			if node.name == 'propname' || node.name == 'D:propname' {
				typ = .propname
				break
			}

			// Check for prop
			if node.name == 'prop' || node.name == 'D:prop' {
				typ = .prop

				// Extract property names
				for prop_child in node.children {
					if prop_child is xml.XMLNode {
						prop_node := prop_child as xml.XMLNode
						props << prop_node.name
					}
				}
				break
			}
		}
	}

	if typ == .invalid {
		return error('Invalid PROPFIND request: missing prop, allprop, or propname element')
	}

	return PropfindRequest{
		typ:         typ
		props:       props
		depth:       depth
		xml_content: data
	}
}

// parse_depth parses the Depth header value
pub fn parse_depth(depth_str string) Depth {
	if depth_str == 'infinity' {
		return .infinity
	} else if depth_str == '0' {
		return .zero
	} else if depth_str == '1' {
		return .one
	} else {
		log.warn('[WebDAV] Invalid Depth header value: ${depth_str}, defaulting to infinity')
		return .infinity
	}
}

// Response represents a WebDAV response for a resource
pub struct PropfindResponse {
pub:
	href            string
	found_props     []Property
	not_found_props []Property
}

fn (r PropfindResponse) xml() xml.XMLNodeContents {
	return xml.XMLNode{
		name:     'D:response'
		children: [
			xml.XMLNode{
				name:     'D:href'
				children: [xml.XMLNodeContents(r.href)]
			},
			xml.XMLNode{
				name:     'D:propstat'
				children: [xml.XMLNode{
					name:     'D:prop'
					children: r.found_props.map(it.xml())
				}, xml.XMLNode{
					name:     'D:status'
					children: [xml.XMLNodeContents('HTTP/1.1 200 OK')]
				}]
			},
		]
	}
}

// generate_propfind_response generates a PROPFIND response XML string from Response structs
pub fn (r []PropfindResponse) xml() string {
	// Create multistatus root node
	multistatus_node := xml.XMLNode{
		name:       'D:multistatus'
		attributes: {
			'xmlns:D': 'DAV:'
		}
		children:   r.map(it.xml())
	}

	// Create a new XML document with the root node
	doc := xml.XMLDocument{
		version: '1.0'
		root:    multistatus_node
	}

	// Generate XML string
	doc.validate() or { panic('this should never happen ${err}') }
	return format_xml(doc.str())
}

fn get_file_content_type(path string) string {
	ext := path.all_after_last('.')
	content_type := if v := veb.mime_types[ext] {
		v
	} else {
		'text/plain; charset=utf-8'
	}

	return content_type
}

// parse_xml takes an XML string and returns a cleaned version with whitespace removed between tags
pub fn format_xml(xml_str string) string {
	mut result := ''
	mut i := 0
	mut in_tag := false
	mut content_start := 0

	// Process the string character by character
	for i < xml_str.len {
		ch := xml_str[i]

		// Start of a tag
		if ch == `<` {
			// If we were collecting content between tags, process it
			if !in_tag && i > content_start {
				// Get the content between tags and trim whitespace
				content := xml_str[content_start..i].trim_space()
				result += content
			}

			in_tag = true
			result += '<'
		}
		// End of a tag
		else if ch == `>` {
			in_tag = false
			result += '>'
			content_start = i + 1
		}
		// Inside a tag - preserve all characters including whitespace
		else if in_tag {
			result += ch.ascii_str()
		}
		// Outside a tag - only add non-whitespace or handle whitespace in content
		else if !in_tag {
			// We'll collect and process this content when we reach the next tag
			// or at the end of the string
		}

		i++
	}

	// Handle any remaining content at the end of the string
	if !in_tag && content_start < xml_str.len {
		content := xml_str[content_start..].trim_space()
		result += content
	}

	return result
}
