module heroserver

import freeflowuniverse.herolib.schemas.openrpc
import os
import freeflowuniverse.herolib.schemas.jsonschema

// Generate HTML documentation for handler type
pub fn (s HeroServer) generate_documentation(handler_type string, handler openrpc.Handler) !string {
    spec := s.handler_registry.get_spec(handler_type) or {
        return error('No spec found for handler type: ${handler_type}')
    }

    // Load and process template
    template_path := os.join_path(@VMODROOT, 'lib/hero/heroserver/templates/doc.md')
    template_content := os.read_file(template_path) or {
        return error('Failed to read documentation template: ${err}')
    }

    // Process template with spec data
    doc_content := process_doc_template(template_content, spec, handler_type)

    // Return HTML with Bootstrap and markdown processing
    return generate_html_wrapper(doc_content, handler_type)
}

// Process the markdown template with OpenRPC spec data
fn process_doc_template(template string, spec openrpc.OpenRPC, handler_type string) string {
    mut content := template

    // Replace template variables
    content = content.replace('@{handler_type}', handler_type)
    content = content.replace('@{spec.info.title}', spec.info.title)
    content = content.replace('@{spec.info.description}', spec.info.description)
    content = content.replace('@{spec.info.version}', spec.info.version)

    // Generate methods documentation
    mut methods_doc := ''
    for method in spec.methods {
        methods_doc += generate_method_doc(method)
    }
    content = content.replace('@{methods}', methods_doc)

    return content
}

// Generate documentation for a single method
fn generate_method_doc(method openrpc.Method) string {
    mut doc := '## ${method.name}\n\n'

    if method.description.len > 0 {
        doc += '${method.description}\n\n'
    }

    // Parameters
    if method.params.len > 0 {
        doc += '### Parameters\n\n'
        for param in method.params {
            // Handle both ContentDescriptor and Reference
            if param is openrpc.ContentDescriptor {
                if param.schema is jsonschema.Schema {
                    schema := param.schema as jsonschema.Schema
                    doc += '- **${param.name}** (${schema.typ}): ${param.description}\n'
                }
            }
        }
        doc += '\n'
    }

    // Result
    if method.result is openrpc.ContentDescriptor {
        result := method.result as openrpc.ContentDescriptor
        doc += '### Returns\n\n'
        doc += '${result.description}\n\n'
    }

    // Examples (would need to be added to OpenRPC spec or handled differently)
    doc += '### Example\n\n'
    doc += '```json\n'
    doc += '// Request example would go here\n'
    doc += '```\n\n'

    return doc
}

// Generate HTML wrapper with Bootstrap
fn generate_html_wrapper(markdown_content string, handler_type string) string {
	template_path := os.join_path(@VMODROOT, 'lib/hero/heroserver/templates/doc_wrapper.html')
	mut template_content := os.read_file(template_path) or { return 'Template not found' }
	template_content = template_content.replace('@{handler_type}', handler_type)
	template_content = template_content.replace('@{markdown_content}', markdown_content)
	return template_content
}