# module html


## Contents
- [parse](#parse)
- [parse_file](#parse_file)
- [CloseTagType](#CloseTagType)
- [DocumentObjectModel](#DocumentObjectModel)
  - [get_root](#get_root)
  - [get_tags](#get_tags)
  - [get_tags_by_class_name](#get_tags_by_class_name)
  - [get_tags_by_attribute](#get_tags_by_attribute)
  - [get_tags_by_attribute_value](#get_tags_by_attribute_value)
- [GetTagsOptions](#GetTagsOptions)
- [Parser](#Parser)
  - [add_code_tag](#add_code_tag)
  - [split_parse](#split_parse)
  - [parse_html](#parse_html)
  - [finalize](#finalize)
  - [get_dom](#get_dom)
- [Tag](#Tag)
  - [text](#text)
  - [str](#str)
  - [get_tag](#get_tag)
  - [get_tags](#get_tags)
  - [get_tag_by_attribute](#get_tag_by_attribute)
  - [get_tags_by_attribute](#get_tags_by_attribute)
  - [get_tag_by_attribute_value](#get_tag_by_attribute_value)
  - [get_tags_by_attribute_value](#get_tags_by_attribute_value)
  - [get_tag_by_class_name](#get_tag_by_class_name)
  - [get_tags_by_class_name](#get_tags_by_class_name)

## parse
```v
fn parse(text string) DocumentObjectModel
```

parse parses and returns the DOM from the given text.

Note: this function converts tags to lowercase. E.g. <MyTag>content</MyTag> is parsed as <mytag>content</mytag>.

[[Return to contents]](#Contents)

## parse_file
```v
fn parse_file(filename string) DocumentObjectModel
```

parse_file parses and returns the DOM from the contents of a file.

Note: this function converts tags to lowercase. E.g. <MyTag>content</MyTag> is parsed as <mytag>content</mytag>.

[[Return to contents]](#Contents)

## CloseTagType
```v
enum CloseTagType {
	in_name
	new_tag
}
```

[[Return to contents]](#Contents)

## DocumentObjectModel
```v
struct DocumentObjectModel {
mut:
	root           &Tag = unsafe { nil }
	constructed    bool
	btree          BTree
	all_tags       []&Tag
	all_attributes map[string][]&Tag
	close_tags     map[string]bool // add a counter to see count how many times is closed and parse correctly
	attributes     map[string][]string
	tag_attributes map[string][][]&Tag
	tag_type       map[string][]&Tag
	debug_file     os.File
}
```

The W3C Document Object Model (DOM) is a platform and language-neutral interface that allows programs and scripts to dynamically access and update the content, structure, and style of a document.

https://www.w3.org/TR/WD-DOM/introduction.html

[[Return to contents]](#Contents)

## get_root
```v
fn (dom &DocumentObjectModel) get_root() &Tag
```

get_root returns the root of the document.

[[Return to contents]](#Contents)

## get_tags
```v
fn (dom &DocumentObjectModel) get_tags(options GetTagsOptions) []&Tag
```

get_tags returns all tags stored in the document.

[[Return to contents]](#Contents)

## get_tags_by_class_name
```v
fn (dom &DocumentObjectModel) get_tags_by_class_name(names ...string) []&Tag
```

get_tags_by_class_name retrieves all tags recursively in the document root that have the given class name(s).

[[Return to contents]](#Contents)

## get_tags_by_attribute
```v
fn (dom &DocumentObjectModel) get_tags_by_attribute(name string) []&Tag
```

get_tags_by_attribute retrieves all tags in the document that have the given attribute name.

[[Return to contents]](#Contents)

## get_tags_by_attribute_value
```v
fn (mut dom DocumentObjectModel) get_tags_by_attribute_value(name string, value string) []&Tag
```

get_tags_by_attribute_value retrieves all tags in the document that have the given attribute name and value.

[[Return to contents]](#Contents)

## GetTagsOptions
```v
struct GetTagsOptions {
pub:
	name string
}
```

[[Return to contents]](#Contents)

## Parser
```v
struct Parser {
mut:
	dom                DocumentObjectModel
	lexical_attributes LexicalAttributes = LexicalAttributes{
		current_tag: &Tag{}
	}
	filename           string = 'direct-parse'
	initialized        bool
	tags               []&Tag
	debug_file         os.File
}
```

Parser is responsible for reading the HTML strings and converting them into a `DocumentObjectModel`.

[[Return to contents]](#Contents)

## add_code_tag
```v
fn (mut parser Parser) add_code_tag(name string)
```

This function is used to add a tag for the parser ignore it's content. For example, if you have an html or XML with a custom tag, like `<script>`, using this function, like `add_code_tag('script')` will make all `script` tags content be jumped, so you still have its content, but will not confuse the parser with it's `>` or `<`.

[[Return to contents]](#Contents)

## split_parse
```v
fn (mut parser Parser) split_parse(data string)
```

split_parse parses the HTML fragment

[[Return to contents]](#Contents)

## parse_html
```v
fn (mut parser Parser) parse_html(data string)
```

parse_html parses the given HTML string

[[Return to contents]](#Contents)

## finalize
```v
fn (mut parser Parser) finalize()
```

finalize finishes the parsing stage .

[[Return to contents]](#Contents)

## get_dom
```v
fn (mut parser Parser) get_dom() DocumentObjectModel
```

get_dom returns the parser's current DOM representation.

[[Return to contents]](#Contents)

## Tag
```v
struct Tag {
pub mut:
	name               string
	content            string
	children           []&Tag
	attributes         map[string]string // attributes will be like map[name]value
	last_attribute     string
	class_set          datatypes.Set[string]
	parent             &Tag = unsafe { nil }
	position_in_parent int
	closed             bool
	close_type         CloseTagType = .in_name
}
```

Tag holds the information of an HTML tag.

[[Return to contents]](#Contents)

## text
```v
fn (tag &Tag) text() string
```

text returns the text contents of the tag.

[[Return to contents]](#Contents)

## str
```v
fn (tag &Tag) str() string
```

[[Return to contents]](#Contents)

## get_tag
```v
fn (tag &Tag) get_tag(name string) ?&Tag
```

get_tag retrieves the first found child tag in the tag that has the given tag name.

[[Return to contents]](#Contents)

## get_tags
```v
fn (tag &Tag) get_tags(name string) []&Tag
```

get_tags retrieves all child tags recursively in the tag that have the given tag name.

[[Return to contents]](#Contents)

## get_tag_by_attribute
```v
fn (tag &Tag) get_tag_by_attribute(name string) ?&Tag
```

get_tag_by_attribute retrieves the first found child tag in the tag that has the given attribute name.

[[Return to contents]](#Contents)

## get_tags_by_attribute
```v
fn (tag &Tag) get_tags_by_attribute(name string) []&Tag
```

get_tags_by_attribute retrieves all child tags recursively in the tag that have the given attribute name.

[[Return to contents]](#Contents)

## get_tag_by_attribute_value
```v
fn (tag &Tag) get_tag_by_attribute_value(name string, value string) ?&Tag
```

get_tag_by_attribute_value retrieves the first found child tag in the tag that has the given attribute name and value.

[[Return to contents]](#Contents)

## get_tags_by_attribute_value
```v
fn (tag &Tag) get_tags_by_attribute_value(name string, value string) []&Tag
```

get_tags_by_attribute_value retrieves all child tags recursively in the tag that have the given attribute name and value.

[[Return to contents]](#Contents)

## get_tag_by_class_name
```v
fn (tag &Tag) get_tag_by_class_name(names ...string) ?&Tag
```

get_tag_by_class_name retrieves the first found child tag in the tag that has the given class name(s).

[[Return to contents]](#Contents)

## get_tags_by_class_name
```v
fn (tag &Tag) get_tags_by_class_name(names ...string) []&Tag
```

get_tags_by_class_name retrieves all child tags recursively in the tag that have the given class name(s).

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
