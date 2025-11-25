module codeparser

// import incubaid.herolib.core.pathlib
// import incubaid.herolib.core.code

@[params]
pub struct ParserOptions {
pub:
	path             string @[required]
	recursive        bool = true
	exclude_patterns []string
	include_patterns []string = ['*.v']
}

// new creates a CodeParser and scans the given root directory
pub fn new(args ParserOptions) !CodeParser {
	mut parser := CodeParser{
		root_dir:     args.path
		options:      args
		parsed_files: map[string]ParsedFile{}
		modules:      map[string][]string{}
		parse_errors: []ParseError{}
	}
	parser.scan_directory()!
	return parser
}
