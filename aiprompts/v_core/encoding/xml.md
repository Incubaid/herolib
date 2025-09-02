# module xml


## Contents
- [Constants](#Constants)
- [escape_text](#escape_text)
- [parse_single_node](#parse_single_node)
- [unescape_text](#unescape_text)
- [XMLDocument.from_file](#XMLDocument.from_file)
- [XMLDocument.from_reader](#XMLDocument.from_reader)
- [XMLDocument.from_string](#XMLDocument.from_string)
- [DTDListItem](#DTDListItem)
- [XMLNodeContents](#XMLNodeContents)
- [DTDElement](#DTDElement)
- [DTDEntity](#DTDEntity)
- [DocumentType](#DocumentType)
- [DocumentTypeDefinition](#DocumentTypeDefinition)
- [EscapeConfig](#EscapeConfig)
- [UnescapeConfig](#UnescapeConfig)
- [XMLCData](#XMLCData)
- [XMLComment](#XMLComment)
- [XMLDocument](#XMLDocument)
  - [get_element_by_id](#get_element_by_id)
  - [get_elements_by_attribute](#get_elements_by_attribute)
  - [get_elements_by_tag](#get_elements_by_tag)
  - [pretty_str](#pretty_str)
  - [str](#str)
  - [validate](#validate)
- [XMLNode](#XMLNode)
  - [get_element_by_id](#get_element_by_id)
  - [get_elements_by_attribute](#get_elements_by_attribute)
  - [get_elements_by_tag](#get_elements_by_tag)
  - [pretty_str](#pretty_str)

## Constants
```v
const default_entities = {
	'lt':   '<'
	'gt':   '>'
	'amp':  '&'
	'apos': "'"
	'quot': '"'
}
```

[[Return to contents]](#Contents)

```v
const default_entities_reverse = {
	'<': 'lt'
	'>': 'gt'
	'&': 'amp'
	"'": 'apos'
	'"': 'quot'
}
```

[[Return to contents]](#Contents)

## escape_text
```v
fn escape_text(content string, config EscapeConfig) string
```

escape_text replaces all entities in the given string with their respective XML entity strings. See default_entities, which can be overridden.

[[Return to contents]](#Contents)

## parse_single_node
```v
fn parse_single_node(first_char u8, mut reader io.Reader) !XMLNode
```

parse_single_node parses a single XML node from the reader. The first character of the tag is passed in as the first_char parameter. This function is meant to assist in parsing nested nodes one at a time. Using this function as opposed to the recommended static functions makes it easier to parse smaller nodes in extremely large XML documents without running out of memory.

[[Return to contents]](#Contents)

## unescape_text
```v
fn unescape_text(content string, config UnescapeConfig) !string
```

unescape_text replaces all entities in the given string with their respective original characters or strings. See default_entities_reverse, which can be overridden.

[[Return to contents]](#Contents)

## XMLDocument.from_file
```v
fn XMLDocument.from_file(path string) !XMLDocument
```

XMLDocument.from_file parses an XML document from a file. Note that the file is read in its entirety and then parsed. If the file is too large, try using the XMLDocument.from_reader function instead.

[[Return to contents]](#Contents)

## XMLDocument.from_reader
```v
fn XMLDocument.from_reader(mut reader io.Reader) !XMLDocument
```

XMLDocument.from_reader parses an XML document from a reader. This is the most generic way to parse an XML document from any arbitrary source that implements that io.Reader interface.

[[Return to contents]](#Contents)

## XMLDocument.from_string
```v
fn XMLDocument.from_string(raw_contents string) !XMLDocument
```

XMLDocument.from_string parses an XML document from a string.

[[Return to contents]](#Contents)

## DTDListItem
```v
type DTDListItem = DTDElement | DTDEntity
```

[[Return to contents]](#Contents)

## XMLNodeContents
```v
type XMLNodeContents = XMLCData | XMLComment | XMLNode | string
```

[[Return to contents]](#Contents)

## DTDElement
```v
struct DTDElement {
pub:
	name       string   @[required]
	definition []string @[required]
}
```

[[Return to contents]](#Contents)

## DTDEntity
```v
struct DTDEntity {
pub:
	name  string @[required]
	value string @[required]
}
```

[[Return to contents]](#Contents)

## DocumentType
```v
struct DocumentType {
pub:
	name string @[required]
	dtd  DTDInfo
}
```

[[Return to contents]](#Contents)

## DocumentTypeDefinition
```v
struct DocumentTypeDefinition {
pub:
	name string
	list []DTDListItem
}
```

[[Return to contents]](#Contents)

## EscapeConfig
```v
struct EscapeConfig {
pub:
	reverse_entities map[string]string = default_entities_reverse
}
```

[[Return to contents]](#Contents)

## UnescapeConfig
```v
struct UnescapeConfig {
pub:
	entities map[string]string = default_entities
}
```

[[Return to contents]](#Contents)

## XMLCData
```v
struct XMLCData {
pub:
	text string @[required]
}
```

[[Return to contents]](#Contents)

## XMLComment
```v
struct XMLComment {
pub:
	text string @[required]
}
```

[[Return to contents]](#Contents)

## XMLDocument
```v
struct XMLDocument {
	Prolog
pub:
	root XMLNode @[required]
}
```

XMLDocument is the struct that represents a single XML document. It contains the prolog and the single root node. The prolog struct is embedded into the XMLDocument struct, so that the prolog fields are accessible directly from the this struct. Public prolog fields include version, enccoding, comments preceding the root node, and the document type definition.

[[Return to contents]](#Contents)

## get_element_by_id
```v
fn (doc XMLDocument) get_element_by_id(id string) ?XMLNode
```

get_element_by_id returns the first element with the given id, or none if no such element exists.

[[Return to contents]](#Contents)

## get_elements_by_attribute
```v
fn (doc XMLDocument) get_elements_by_attribute(attribute string, value string) []XMLNode
```

get_elements_by_attribute returns all elements with the given attribute-value pair. If there are no such elements, an empty array is returned.

[[Return to contents]](#Contents)

## get_elements_by_tag
```v
fn (doc XMLDocument) get_elements_by_tag(tag string) []XMLNode
```

get_elements_by_tag returns all elements with the given tag name. If there are no such elements, an empty array is returned.

[[Return to contents]](#Contents)

## pretty_str
```v
fn (doc XMLDocument) pretty_str(indent string) string
```

pretty_str returns a pretty-printed version of the XML document. It requires the string used to indent each level of the document.

[[Return to contents]](#Contents)

## str
```v
fn (doc XMLDocument) str() string
```

str returns a string representation of the XML document. It uses a 2-space indentation to pretty-print the document.

[[Return to contents]](#Contents)

## validate
```v
fn (doc XMLDocument) validate() !XMLDocument
```

validate checks the document is well-formed and valid. It returns a new document with the parsed entities expanded when validation is successful. Otherwise it returns an error.

[[Return to contents]](#Contents)

## XMLNode
```v
struct XMLNode {
pub:
	name       string @[required]
	attributes map[string]string
	children   []XMLNodeContents
}
```

XMLNode represents a single XML node. It contains the node name, a map of attributes, and a list of children. The children can be other XML nodes, CDATA, plain text, or comments.

[[Return to contents]](#Contents)

## get_element_by_id
```v
fn (node XMLNode) get_element_by_id(id string) ?XMLNode
```

get_element_by_id returns the first element with the given id, or none if no such element exists in the subtree rooted at this node.

[[Return to contents]](#Contents)

## get_elements_by_attribute
```v
fn (node XMLNode) get_elements_by_attribute(attribute string, value string) []XMLNode
```

get_elements_by_attribute returns all elements with the given attribute-value pair in the subtree rooted at this node. If there are no such elements, an empty array is returned.

[[Return to contents]](#Contents)

## get_elements_by_tag
```v
fn (node XMLNode) get_elements_by_tag(tag string) []XMLNode
```

get_elements_by_tag returns all elements with the given tag name in the subtree rooted at this node. If there are no such elements, an empty array is returned.

[[Return to contents]](#Contents)

## pretty_str
```v
fn (node XMLNode) pretty_str(original_indent string, depth int, reverse_entities map[string]string) string
```

pretty_str returns a pretty-printed version of the XML node. It requires the current indentation the node is at, the depth of the node in the tree, and a map of reverse entities to use when escaping text.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
