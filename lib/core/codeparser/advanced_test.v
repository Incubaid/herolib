module codeparser

import incubaid.herolib.ui.console
import incubaid.herolib.core.pathlib
import incubaid.herolib.core.code
import os

fn test_comprehensive_code_parsing() {
	console.print_header('Comprehensive Code Parsing Tests')
	console.print_lf(1)

	// Setup test files by copying testdata
	test_dir := setup_test_directory()
	console.print_item('Copied testdata to: ${test_dir}')
	console.print_lf(1)

	// Run all tests
	check_module_parsing()!
	check_struct_parsing()
	check_function_parsing()!
	check_imports_and_modules()
	check_type_system()
	check_visibility_modifiers()
	check_method_parsing()!
	check_constants_parsing()

	console.print_green('✓ All comprehensive tests passed!')
	console.print_lf(1)

	// Cleanup
	os.rmdir_all(test_dir) or {}
	console.print_item('Cleaned up test directory')
}

// setup_test_directory copies the testdata directory to /tmp/codeparsertest
fn setup_test_directory() string {
	test_dir := '/tmp/codeparsertest'

	// Remove existing test directory
	os.rmdir_all(test_dir) or {}

	// Find the testdata directory relative to this file
	current_file := @FILE
	current_dir := os.dir(current_file)
	testdata_dir := os.join_path(current_dir, 'testdata')

	// Verify testdata directory exists
	if !os.is_dir(testdata_dir) {
		panic('testdata directory not found at: ${testdata_dir}')
	}

	// Copy testdata to test directory
	os.mkdir_all(test_dir) or { panic('Failed to create test directory') }
	copy_directory(testdata_dir, test_dir) or { panic('Failed to copy testdata: ${err}') }

	return test_dir
}

// copy_directory recursively copies a directory and all its contents
fn copy_directory(src string, dst string) ! {
	entries := os.ls(src)!

	for entry in entries {
		src_path := os.join_path(src, entry)
		dst_path := os.join_path(dst, entry)

		if os.is_dir(src_path) {
			os.mkdir_all(dst_path)!
			copy_directory(src_path, dst_path)!
		} else {
			content := os.read_file(src_path)!
			os.write_file(dst_path, content)!
		}
	}
}

fn check_module_parsing() ! {
	console.print_header('Test 1: Module and File Parsing')

	mut myparser := new(path: '/tmp/codeparsertest', recursive: true)!
	myparser.parse()!

	v_files := myparser.list_files()
	console.print_item('Found ${v_files.len} V files')

	mut total_items := 0
	for file_path in v_files {
		if parsed_file := myparser.parsed_files[file_path] {
			console.print_item('  ✓ ${os.base(file_path)}: ${parsed_file.vfile.items.len} items')
			total_items += parsed_file.vfile.items.len
		}
	}

	assert v_files.len >= 7, 'Expected at least 7 V files, got ${v_files.len}'
	assert total_items > 0, 'Expected to parse some items'

	console.print_green('✓ Module parsing test passed')
	console.print_lf(1)
}

fn check_struct_parsing() {
	console.print_header('Test 2: Struct Parsing')

	models_file := os.join_path('/tmp/codeparsertest', 'models.v')
	content := os.read_file(models_file) or {
		assert false, 'Failed to read models.v'
		return
	}

	vfile := code.parse_vfile(content) or {
		assert false, 'Failed to parse models.v: ${err}'
		return
	}

	structs := vfile.structs()
	assert structs.len >= 3, 'Expected at least 3 structs, got ${structs.len}'

	// Check User struct
	user_struct := structs.filter(it.name == 'User')
	assert user_struct.len == 1, 'User struct not found'
	user := user_struct[0]
	assert user.is_pub == true, 'User struct should be public'
	assert user.fields.len == 6, 'User struct should have 6 fields, got ${user.fields.len}'
	console.print_item('  ✓ User struct: ${user.fields.len} fields (public)')

	// Check Profile struct
	profile_struct := structs.filter(it.name == 'Profile')
	assert profile_struct.len == 1, 'Profile struct not found'
	assert profile_struct[0].is_pub == true, 'Profile should be public'
	console.print_item('  ✓ Profile struct: ${profile_struct[0].fields.len} fields (public)')

	// Check Settings struct (private)
	settings_struct := structs.filter(it.name == 'Settings')
	assert settings_struct.len == 1, 'Settings struct not found'
	assert settings_struct[0].is_pub == false, 'Settings should be private'
	console.print_item('  ✓ Settings struct: ${settings_struct[0].fields.len} fields (private)')

	// Check InternalConfig struct
	config_struct := structs.filter(it.name == 'InternalConfig')
	assert config_struct.len == 1, 'InternalConfig struct not found'
	assert config_struct[0].is_pub == false, 'InternalConfig should be private'
	console.print_item('  ✓ InternalConfig struct (private)')

	console.print_green('✓ Struct parsing test passed')
	console.print_lf(1)
}

fn check_function_parsing() ! {
	console.print_header('Test 3: Function Parsing')

	mut myparser := new(path: '/tmp/codeparsertest', recursive: true)!
	myparser.parse()!

	mut functions := []code.Function{}
	for _, parsed_file in myparser.parsed_files {
		functions << parsed_file.vfile.functions()
	}

	pub_functions := functions.filter(it.is_pub)
	priv_functions := functions.filter(!it.is_pub)

	assert pub_functions.len >= 8, 'Expected at least 8 public functions, got ${pub_functions.len}'
	assert priv_functions.len >= 4, 'Expected at least 4 private functions, got ${priv_functions.len}'

	// Check create_user function
	create_user_fn := functions.filter(it.name == 'create_user')
	assert create_user_fn.len == 1, 'create_user function not found'
	create_fn := create_user_fn[0]
	assert create_fn.is_pub == true, 'create_user should be public'
	assert create_fn.params.len == 2, 'create_user should have 2 parameters'
	console.print_item('  ✓ create_user: ${create_fn.params.len} params, public')

	// Check get_user function
	get_user_fn := functions.filter(it.name == 'get_user')
	assert get_user_fn.len == 1, 'get_user function not found'
	assert get_user_fn[0].is_pub == true
	console.print_item('  ✓ get_user: public function')

	// Check delete_user function
	delete_user_fn := functions.filter(it.name == 'delete_user')
	assert delete_user_fn.len == 1, 'delete_user function not found'
	console.print_item('  ✓ delete_user: public function')

	// Check validate_email (private)
	validate_fn := functions.filter(it.name == 'validate_email')
	assert validate_fn.len == 1, 'validate_email function not found'
	assert validate_fn[0].is_pub == false, 'validate_email should be private'
	console.print_item('  ✓ validate_email: private function')

	console.print_green('✓ Function parsing test passed')
	console.print_lf(1)
}

fn check_imports_and_modules() {
	console.print_header('Test 4: Imports and Module Names')

	models_file := os.join_path('/tmp/codeparsertest', 'models.v')
	content := os.read_file(models_file) or {
		assert false, 'Failed to read models.v'
		return
	}

	vfile := code.parse_vfile(content) or {
		assert false, 'Failed to parse models.v: ${err}'
		return
	}

	assert vfile.mod == 'testdata', 'Module name should be testdata, got ${vfile.mod}'
	assert vfile.imports.len == 2, 'Expected 2 imports, got ${vfile.imports.len}'

	console.print_item('  ✓ Module name: ${vfile.mod}')
	console.print_item('  ✓ Imports: ${vfile.imports.len}')

	for import_ in vfile.imports {
		console.print_item('    - ${import_.mod}')
	}

	assert 'time' in vfile.imports.map(it.mod), 'time import not found'
	assert 'os' in vfile.imports.map(it.mod), 'os import not found'

	console.print_green('✓ Import and module test passed')
	console.print_lf(1)
}

fn check_type_system() {
	console.print_header('Test 5: Type System')

	models_file := os.join_path('/tmp/codeparsertest', 'models.v')
	content := os.read_file(models_file) or {
		assert false, 'Failed to read models.v'
		return
	}

	vfile := code.parse_vfile(content) or {
		assert false, 'Failed to parse models.v: ${err}'
		return
	}

	structs := vfile.structs()
	user_struct := structs.filter(it.name == 'User')[0]

	// Test different field types
	id_field := user_struct.fields.filter(it.name == 'id')[0]
	assert id_field.typ.symbol() == 'int', 'id field should be int, got ${id_field.typ.symbol()}'

	email_field := user_struct.fields.filter(it.name == 'email')[0]
	assert email_field.typ.symbol() == 'string', 'email field should be string'

	active_field := user_struct.fields.filter(it.name == 'active')[0]
	assert active_field.typ.symbol() == 'bool', 'active field should be bool'

	console.print_item('  ✓ Integer type: ${id_field.typ.symbol()}')
	console.print_item('  ✓ String type: ${email_field.typ.symbol()}')
	console.print_item('  ✓ Boolean type: ${active_field.typ.symbol()}')

	console.print_green('✓ Type system test passed')
	console.print_lf(1)
}

fn check_visibility_modifiers() {
	console.print_header('Test 6: Visibility Modifiers')

	models_file := os.join_path('/tmp/codeparsertest', 'models.v')
	content := os.read_file(models_file) or {
		assert false, 'Failed to read models.v'
		return
	}

	vfile := code.parse_vfile(content) or {
		assert false, 'Failed to parse models.v: ${err}'
		return
	}

	structs := vfile.structs()

	// Check User struct visibility
	user_struct := structs.filter(it.name == 'User')[0]
	assert user_struct.is_pub == true, 'User struct should be public'

	pub_fields := user_struct.fields.filter(it.is_pub)
	mut_fields := user_struct.fields.filter(it.is_mut)

	console.print_item('  ✓ User struct: public')
	console.print_item('    - Public fields: ${pub_fields.len}')
	console.print_item('    - Mutable fields: ${mut_fields.len}')

	// Check InternalConfig visibility
	config_struct := structs.filter(it.name == 'InternalConfig')[0]
	assert config_struct.is_pub == false, 'InternalConfig should be private'
	console.print_item('  ✓ InternalConfig: private')

	console.print_green('✓ Visibility modifiers test passed')
	console.print_lf(1)
}

fn check_method_parsing() ! {
	console.print_header('Test 7: Method Parsing')

	mut myparser := new(path: '/tmp/codeparsertest', recursive: true)!
	myparser.parse()!

	mut methods := []code.Function{}
	for _, parsed_file in myparser.parsed_files {
		methods << parsed_file.vfile.functions().filter(it.receiver.name != '')
	}

	assert methods.len >= 11, 'Expected at least 11 methods, got ${methods.len}'

	// Check activate method
	activate_methods := methods.filter(it.name == 'activate')
	assert activate_methods.len == 1, 'activate method not found'
	assert activate_methods[0].receiver.mutable == true, 'activate should have mutable receiver'
	console.print_item('  ✓ activate: mutable method')

	// Check is_active method
	is_active_methods := methods.filter(it.name == 'is_active')
	assert is_active_methods.len == 1, 'is_active method not found'
	assert is_active_methods[0].receiver.mutable == false, 'is_active should have immutable receiver'
	console.print_item('  ✓ is_active: immutable method')

	// Check get_display_name method
	display_methods := methods.filter(it.name == 'get_display_name')
	assert display_methods.len == 1, 'get_display_name method not found'
	console.print_item('  ✓ get_display_name: method found')

	console.print_green('✓ Method parsing test passed')
	console.print_lf(1)
}

fn check_constants_parsing() {
	console.print_header('Test 8: Constants Parsing')

	models_file := os.join_path('/tmp/codeparsertest', 'models.v')
	content := os.read_file(models_file) or {
		assert false, 'Failed to read models.v'
		return
	}

	vfile := code.parse_vfile(content) or {
		assert false, 'Failed to parse models.v: ${err}'
		return
	}

	assert vfile.consts.len == 3, 'Expected 3 constants, got ${vfile.consts.len}'

	// Check app_version constant
	version_const := vfile.consts.filter(it.name == 'app_version')
	assert version_const.len == 1, 'app_version constant not found'
	console.print_item('  ✓ app_version: ${version_const[0].value}')

	// Check max_users constant
	max_users_const := vfile.consts.filter(it.name == 'max_users')
	assert max_users_const.len == 1, 'max_users constant not found'
	console.print_item('  ✓ max_users: ${max_users_const[0].value}')

	// Check default_timeout constant
	timeout_const := vfile.consts.filter(it.name == 'default_timeout')
	assert timeout_const.len == 1, 'default_timeout constant not found'
	console.print_item('  ✓ default_timeout: ${timeout_const[0].value}')

	console.print_green('✓ Constants parsing test passed')
	console.print_lf(1)
}
