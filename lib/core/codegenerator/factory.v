module codegenerator

@[params]
pub struct GeneratorOptions {
pub:
	parser_path string @[required]
	output_dir  string @[required]
	recursive   bool = true
	format      bool = true
}

pub fn new(args GeneratorOptions) !CodeGenerator {
	import incubaid.herolib.core.codeparser
	
	mut parser := codeparser.new(
		path:      args.parser_path
		recursive: args.recursive
	)!
	
	parser.parse()!

	return CodeGenerator{
		parser:     parser
		output_dir: args.output_dir
		format:    args.format
	}
}