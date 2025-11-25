#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.code
import incubaid.herolib.ui.console
import os

console.print_header('Code Parser Example - lib/core/pathlib Analysis')
console.print_lf(1)

pathlib_dir := os.home_dir() + '/code/github/incubaid/herolib/lib/core/pathlib'

// Step 1: List all V files
console.print_header('1. Listing V Files')
v_files := code.list_v_files(pathlib_dir)!
for file in v_files {
	console.print_item(os.base(file))
}
console.print_lf(1)

// Step 2: Parse and analyze each file
console.print_header('2. Parsing Files - Summary')
for v_file_path in v_files {
	content := os.read_file(v_file_path)!
	vfile := code.parse_vfile(content)!

	console.print_item('${os.base(v_file_path)}')
	console.print_item('  Module: ${vfile.mod}')
	console.print_item('  Imports: ${vfile.imports.len}')
	console.print_item('  Structs: ${vfile.structs().len}')
	console.print_item('  Functions: ${vfile.functions().len}')
}
console.print_lf(1)

// // Step 3: Find Path struct
// console.print_header('3. Analyzing Path Struct')
// path_code := code.get_type_from_module(pathlib_dir, 'Path')!
// console.print_stdout(path_code)
// console.print_lf(1)

// Step 4: List all public functions
console.print_header('4. Public Functions in pathlib')
for v_file_path in v_files {
	content := os.read_file(v_file_path)!
	vfile := code.parse_vfile(content)!

	pub_functions := vfile.functions().filter(it.is_pub)
	if pub_functions.len > 0 {
		console.print_item('From ${os.base(v_file_path)}:')
		for f in pub_functions {
			console.print_item('  ${f.name}() -> ${f.result.typ.symbol()}')
		}
	}
}
console.print_lf(1)

console.print_green('✓ Analysis completed!')
