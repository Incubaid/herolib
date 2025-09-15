module code

import freeflowuniverse.herolib.ui.console
import os

// vet_file runs v vet on a single file
// ARGS:
//   file string - path to the file to vet
// RETURNS:
//   string - vet results output, or error if vet fails
fn vet_file(file string) !string {
	cmd := 'v vet -v -w ${file}'
	console.print_debug('Executing command: ${cmd}')
	result := os.execute(cmd)
	if result.exit_code != 0 {
		return error('Vet failed for ${file} with exit code ${result.exit_code}\n${result.output}')
	} else {
		console.print_item('Vet completed for ${file}')
	}
	return 'Command: ${cmd}\nExit code: ${result.exit_code}\nOutput:\n${result.output}'
}

// vvet runs v vet on the specified file or directory
// ARGS:
//   fullpath string - path to the file or directory to vet
// RETURNS:
//   string - vet results output, or error if vet fails
pub fn vvet(fullpath string) !string {
	console.print_item('vet ${fullpath}')
	if !os.exists(fullpath) {
		return error('File or directory does not exist: ${fullpath}')
	}

	if os.is_dir(fullpath) {
		mut results := ''
		files := list_v_files(fullpath) or { return error('Error listing V files: ${err}') }
		for file in files {
			results += vet_file(file) or {
				console.print_stderr('Failed to vet ${file}: ${err}')
				return error('Failed to vet ${file}: ${err}')
			}
			results += '\n-----------------------\n'
		}
		return results
	} else {
		return vet_file(fullpath)
	}
}
