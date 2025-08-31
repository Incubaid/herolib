module generator

import freeflowuniverse.herolib.core.code { File, Folder }
import freeflowuniverse.herolib.core.texttools

// generates the folder with runnable scripts of the actor
pub fn generate_scripts_folder(name string, example bool) Folder {
	actor_name := '${texttools.snake_case(name)}_actor'
	return Folder{
		name:  'scripts'
		files: [
			generate_run_script(actor_name),
			generate_docs_script(actor_name),
			generate_run_actor_script(name),
			generate_run_actor_example_script(name),
			generate_run_http_server_script(name),
			// generate_compile_script(actor_name),
			// generate_generate_script(actor_name)
		]
	}
}

// Function to generate a script for running an actor
fn generate_run_script(actor_name string) File {
	actor_title := texttools.title_case(actor_name)
	dollar := '$'
	return File{
		name:      'run'
		extension: 'sh'
		content:   $tmpl('./templates/run.sh.template')
	}
}

// Function to generate a script for running an actor
fn generate_docs_script(actor_name string) File {
	dollar := '$'
	return File{
		name:      'docs'
		extension: 'vsh'
		content:   $tmpl('./templates/docs.vsh.template')
	}
}

// Function to generate a script for running an actor
fn generate_run_actor_script(name string) File {
	name_snake := texttools.snake_case(name)
	name_pascal := texttools.pascal_case(name)
	return File{
		name:      'run_actor'
		extension: 'vsh'
		content:   $tmpl('./templates/run_actor.vsh.template')
	}
}

// Function to generate a script for running an example actor
fn generate_run_actor_example_script(name string) File {
	name_snake := texttools.snake_case(name)
	name_pascal := texttools.pascal_case(name)
	return File{
		name:      'run_actor_example'
		extension: 'vsh'
		content:   $tmpl('./templates/run_actor_example.vsh.template')
	}
}

// Function to generate a script for running an HTTP server
fn generate_run_http_server_script(name string) File {
	port := 8080
	name_snake := texttools.snake_case(name)
	return File{
		name:      'run_http_server'
		extension: 'vsh'
		content:   $tmpl('./templates/run_http_server.vsh.template')
	}
}
