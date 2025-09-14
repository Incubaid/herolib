module pugconvert

import v.embed_file
import os

@[heap]
pub struct FileLoader {
pub mut:
	embedded_files map[string]embed_file.EmbedFileData @[skip; str: skip]
}

fn (mut loader FileLoader) load() {
	loader.embedded_files['jet'] = $embed_file('templates/jet_instructions.md')
}

fn (mut loader FileLoader) jet() string {
	c := loader.embedded_files['jet'] or { panic('bug embed') }
	return c.to_string()
}

fn loader() FileLoader {
	mut loader := FileLoader{}
	loader.load()
	return loader
}
