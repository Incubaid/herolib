module pugconvert

import freeflowuniverse.herolib.mcp
import x.json2 as json { Any }
import freeflowuniverse.herolib.mcp.aitools.pugconvert
import freeflowuniverse.herolib.core.pathlib
import os

pub fn handler(arguments map[string]Any) !mcp.ToolCallResult {
	path := arguments['path'].str()

	// Check if path exists
	if !os.exists(path) {
		return mcp.ToolCallResult{
			is_error: true
			content:  mcp.result_to_mcp_tool_contents[string]("Error: Path '${path}' does not exist")
		}
	}

	// Determine if path is a file or directory
	is_directory := os.is_dir(path)

	mut message := ''

	if is_directory {
		// Convert all pug files in the directory
		pugconvert.convert_pug(path) or {
			return mcp.ToolCallResult{
				is_error: true
				content:  mcp.result_to_mcp_tool_contents[string]('Error converting pug files in directory: ${err}')
			}
		}
		message = "Successfully converted all pug files in directory '${path}'"
	} else if path.ends_with('.v') {
		// Convert a single pug file
		pugconvert.convert_pug_file(path) or {
			return mcp.ToolCallResult{
				is_error: true
				content:  mcp.result_to_mcp_tool_contents[string]('Error converting pug file: ${err}')
			}
		}
		message = "Successfully converted pug file '${path}'"
	} else {
		return mcp.ToolCallResult{
			is_error: true
			content:  mcp.result_to_mcp_tool_contents[string]("Error: Path '${path}' is not a directory or .pug file")
		}
	}

	return mcp.ToolCallResult{
		is_error: false
		content:  mcp.result_to_mcp_tool_contents[string](message)
	}
}
