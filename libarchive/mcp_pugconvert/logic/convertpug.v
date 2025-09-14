module pugconvert

import freeflowuniverse.herolib.clients.openai
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.core.pathlib
import json

pub fn convert_pug(mydir string) ! {
	mut d := pathlib.get_dir(path: mydir, create: false)!
	list := d.list(regex: [r'.*\.pug$'], include_links: false, files_only: true)!
	for item in list.paths {
		convert_pug_file(item.path)!
	}
}

// extract_template parses AI response content to extract just the template
fn extract_template(raw_content string) string {
	mut content := raw_content

	// First check for </think> tag
	if content.contains('</think>') {
		content = content.split('</think>')[1].trim_space()
	}

	// Look for ```jet code block
	if content.contains('```jet') {
		parts := content.split('```jet')
		if parts.len > 1 {
			end_parts := parts[1].split('```')
			if end_parts.len > 0 {
				content = end_parts[0].trim_space()
			}
		}
	} else if content.contains('```') {
		// If no ```jet, look for regular ``` code block
		parts := content.split('```')
		if parts.len >= 2 {
			// Take the content between the first set of ```
			// This handles both ```content``` and cases where there's only an opening ```
			content = parts[1].trim_space()

			// If we only see an opening ``` but no closing, cleanup any remaining backticks
			// to avoid incomplete formatting markers
			if !content.contains('```') {
				content = content.replace('`', '')
			}
		}
	}

	return content
}

pub fn convert_pug_file(myfile string) ! {
	println(myfile)

	// Create new file path by replacing .pug extension with .jet
	jet_file := myfile.replace('.pug', '.jet')

	// Check if jet file already exists, if so skip processing
	mut jet_path_exist := pathlib.get_file(path: jet_file, create: false)!
	if jet_path_exist.exists() {
		println('Jet file already exists: ${jet_file}. Skipping conversion.')
		return
	}

	mut content_path := pathlib.get_file(path: myfile, create: false)!
	content := content_path.read()!

	mut l := loader()
	mut client := openai.get()!

	base_instruction := '
	You are a template language converter. You convert Pug templates to Jet templates.

	The target template language, Jet, is defined as follows:
	'

	base_user_prompt := '
	Convert this following Pug template to Jet:

	only output the resulting template, no explanation, no steps, just the jet template
	'

	// We'll retry up to 5 times if validation fails
	max_attempts := 5
	mut attempts := 0
	mut is_valid := false
	mut error_message := ''
	mut template := ''

	for attempts < max_attempts && !is_valid {
		attempts++

		mut system_content := texttools.dedent(base_instruction) + '\n' + l.jet()
		mut user_prompt := ''

		// Create different prompts for first attempt vs retries
		if attempts == 1 {
			// First attempt - convert from PUG
			user_prompt = texttools.dedent(base_user_prompt) + '\n' + content

			// Print what we're sending to the AI service
			println('Sending to OpenAI for conversion:')
			println('--------------------------------')
			println(content)
			println('--------------------------------')
		} else {
			// Retries - focus on fixing the previous errors
			println('Attempt ${attempts}: Retrying with error feedback')
			user_prompt = '
The previous Jet template conversion had the following error:
ERROR: ${error_message}

Here was the template that had errors:
```
${template}
```

The original pug input was  was
```
${content}
```

Please fix the template and try again. Learn from feedback and check which jet template was created.
Return only the corrected Jet template.
Dont send back more information than the fixed template, make sure its in jet format.

			' // Print what we're sending for the retry

			println('Sending to OpenAI for correction:')
			println('--------------------------------')
			println(user_prompt)
			println('--------------------------------')
		}

		mut m := openai.Messages{
			messages: [
				openai.Message{
					role:    .system
					content: system_content
				},
				openai.Message{
					role:    .user
					content: user_prompt
				},
			]
		}

		// Create a chat completion request
		res := client.chat_completion(
			msgs:                  m
			model:                 'deepseek-r1-distill-llama-70b'
			max_completion_tokens: 64000
		)!

		println('-----')

		// Print AI response before extraction
		println('Response received from AI:')
		println('--------------------------------')
		println(res.choices[0].message.content)
		println('--------------------------------')

		// Extract the template from the AI response
		template = extract_template(res.choices[0].message.content)

		println('Extracted template for ${myfile}:')
		println('--------------------------------')
		println(template)
		println('--------------------------------')

		// Validate the template
		validation_result := jetvaliditycheck(template) or {
			// If validation service is unavailable, we'll just proceed with the template
			println('Warning: Template validation service unavailable: ${err}')
			break
		}

		// Check if template is valid
		if validation_result.is_valid {
			is_valid = true
			println('Template validation successful!')
		} else {
			error_message = validation_result.error
			println('Template validation failed: ${error_message}')
		}
	}

	// Report the validation outcome
	if is_valid {
		println('Successfully converted template after ${attempts} attempt(s)')
		// Create the file and write the processed content	
		println('Converted to: ${jet_file}')
		mut jet_path := pathlib.get_file(path: jet_file, create: true)!
		jet_path.write(template)!
	} else if attempts >= max_attempts {
		println('Warning: Could not validate template after ${max_attempts} attempts')
		println('Using best attempt despite validation errors: ${error_message}')
		jet_file2 := jet_file.replace('.jet', '_error.jet')
		mut jet_path2 := pathlib.get_file(path: jet_file2, create: true)!
		jet_path2.write(template)!
	}
}
