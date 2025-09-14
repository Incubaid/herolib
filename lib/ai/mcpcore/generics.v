module mcp

pub fn result_to_mcp_tool_contents[T](result T) []ToolContent {
	return [result_to_mcp_tool_content[T](result)]
}

pub fn result_to_mcp_tool_content[T](result T) ToolContent {
	$if T is string {
		return ToolContent{
			typ:  'text'
			text: result.str()
		}
	} $else $if T is int {
		return ToolContent{
			typ:    'number'
			number: result.int()
		}
	} $else $if T is bool {
		return ToolContent{
			typ:     'boolean'
			boolean: result.bool()
		}
	} $else $if result is $array {
		mut items := []ToolContent{}
		for item in result {
			items << result_to_mcp_tool_content(item)
		}
		return ToolContent{
			typ:   'array'
			items: items
		}
	} $else $if T is $struct {
		mut properties := map[string]ToolContent{}
		$for field in T.fields {
			properties[field.name] = result_to_mcp_tool_content(result.$(field.name))
		}
		return ToolContent{
			typ:        'object'
			properties: properties
		}
	} $else {
		panic('Unsupported type: ${typeof(result)}')
	}
}

pub fn array_to_mcp_tool_contents[U](array []U) []ToolContent {
	mut contents := []ToolContent{}
	for item in array {
		contents << result_to_mcp_tool_content(item)
	}
	return contents
}
