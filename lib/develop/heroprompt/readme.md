# heroprompt

To get started

```v


import freeflowuniverse.herolib.develop.heroprompt

// Example Usage:

// 1. Create a new workspace
mut workspace := heroprompt.new(name: 'my_workspace', path: os.getwd())!

// 2. Add a directory to the workspace
workspace.add_dir(path: './my_project_dir')!

// 3. Add a file to the workspace
workspace.add_file(path: './my_project_dir/main.v')!

// 4. Generate a prompt
user_instructions := 'Explain the code in main.v'
prompt_output := workspace.prompt(text: user_instructions)
println(prompt_output)



```
