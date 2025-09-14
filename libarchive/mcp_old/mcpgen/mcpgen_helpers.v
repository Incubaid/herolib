module mcpgen

import freeflowuniverse.herolib.mcp

pub fn result_to_mcp_tool_contents[T](result T) []mcp.ToolContent {
	return [result_to_mcp_tool_content(result)]
}

pub fn result_to_mcp_tool_content[T](result T) mcp.ToolContent {
	return $if T is string {
		mcp.ToolContent{
			typ:  'text'
			text: result.str()
		}
	} $else $if T is int {
		mcp.ToolContent{
			typ:    'number'
			number: result.int()
		}
	} $else $if T is bool {
		mcp.ToolContent{
			typ:     'boolean'
			boolean: result.bool()
		}
	} $else $if result is $array {
		mut items := []mcp.ToolContent{}
		for item in result {
			items << result_to_mcp_tool_content(item)
		}
		return mcp.ToolContent{
			typ:   'array'
			items: items
		}
	} $else $if T is $struct {
		mut properties := map[string]mcp.ToolContent{}
		$for field in T.fields {
			properties[field.name] = result_to_mcp_tool_content(result.$(field.name))
		}
		return mcp.ToolContent{
			typ:        'object'
			properties: properties
		}
	} $else {
		panic('Unsupported type: ${typeof(result)}')
	}
}

pub fn array_to_mcp_tool_contents[U](array []U) []mcp.ToolContent {
	mut contents := []mcp.ToolContent{}
	for item in array {
		contents << result_to_mcp_tool_content(item)
	}
	return contents
}
