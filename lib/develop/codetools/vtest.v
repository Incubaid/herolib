module code

import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.core.code.vlang_utils { list_v_files }
import os

// ===== V LANGUAGE TOOLS =====

// vtest runs v test on the specified file or directory
// ARGS:
//   fullpath string - path to the file or directory to test
// RETURNS:
//   string - test results output, or error if test fails
pub fn vtest(fullpath string) !string {
	console.print_item('test ${fullpath}')
	if !os.exists(fullpath) {
		return error('File or directory does not exist: ${fullpath}')
	}
	if os.is_dir(fullpath) {
		mut results := ''
		for item in list_v_files(fullpath)! {
			results += vtest(item)!
			results += '\n-----------------------\n'
		}
		return results
	} else {
		cmd := 'v -gc none -stats -enable-globals -show-c-output -keepc -n -w -cg -o /tmp/tester.c -g -cc tcc test ${fullpath}'
		console.print_debug('Executing command: ${cmd}')
		result := os.execute(cmd)
		if result.exit_code != 0 {
			return error('Test failed for ${fullpath} with exit code ${result.exit_code}\n${result.output}')
		} else {
			console.print_item('Test completed for ${fullpath}')
		}
		return 'Command: ${cmd}\nExit code: ${result.exit_code}\nOutput:\n${result.output}'
	}
}
