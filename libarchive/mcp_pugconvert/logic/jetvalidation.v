module pugconvert

import freeflowuniverse.herolib.core.httpconnection
import json

// JetTemplateResponse is the expected response structure from the validation service
struct JetTemplateResponse {
	valid   bool
	message string
	error   string
}

// ValidationResult represents the result of a template validation
pub struct ValidationResult {
pub:
	is_valid bool
	error    string
}

// jetvaliditycheck validates a Jet template by sending it to a validation service
// The function sends the template to http://localhost:9020/checkjet for validation
// Returns a ValidationResult containing validity status and any error messages
pub fn jetvaliditycheck(jetcontent string) !ValidationResult {
	// Create HTTP connection to the validation service
	mut conn := httpconnection.HTTPConnection{
		base_url: 'http://localhost:9020'
	}

	// Prepare the request data - template content wrapped in JSON
	template_data := json.encode({
		'template': jetcontent
	})

	// Print what we're sending to the AI service
	// println('Sending to JET validation service:')
	// println('--------------------------------')
	// println(jetcontent)
	// println('--------------------------------')

	// Send the POST request to the validation endpoint
	req := httpconnection.Request{
		prefix:     'checkjet'
		data:       template_data
		dataformat: .json
	}

	// Execute the request
	result := conn.post_json_str(req) or {
		// Handle connection errors
		return ValidationResult{
			is_valid: false
			error:    'Connection error: ${err}'
		}
	}

	// Attempt to parse the response as JSON using the expected struct
	response := json.decode(JetTemplateResponse, result) or {
		// If we can't parse JSON using our struct, the server didn't return the expected format
		return ValidationResult{
			is_valid: false
			error:    'Server returned unexpected format: ${err.msg()}'
		}
	}

	// Use the structured response data
	if response.valid == false {
		error_msg := if response.error != '' {
			response.error
		} else if response.message != '' {
			response.message
		} else {
			'Unknown validation error'
		}

		return ValidationResult{
			is_valid: false
			error:    error_msg
		}
	}

	return ValidationResult{
		is_valid: true
		error:    ''
	}
}
