module codegenerator

import incubaid.herolib.core.pathlib

pub struct MarkdownGenerator {
pub mut:
	generator  CodeGenerator
	output_dir string
}

// write_all writes all generated markdown files to disk
pub fn (mut mgen MarkdownGenerator) write_all() ! {
	modules := mgen.generator.parser.list_modules()

	// Ensure output directory exists
	mut out_dir := pathlib.get_dir(path: mgen.output_dir, create: true)!

	for module_name in modules {
		mgen.write_module(module_name)!
	}
}

// write_module writes a single module's markdown to disk
pub fn (mut mgen MarkdownGenerator) write_module(module_name string) ! {
	md := mgen.generator.module_to_markdown(module_name)!
	filename := mgen.generator.module_to_filename(module_name)

	filepath := mgen.output_dir + '/' + filename
	mut file := pathlib.get_file(path: filepath, create: true)!
	file.write(md)!
}
