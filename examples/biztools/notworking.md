# BizTools Examples Test Results

## Working Examples
All examples have been fixed and now work correctly:

- `bizmodel.vsh` - This example was already working correctly.
- `bizmodel1.vsh` - Fixed to use `playbook.new()` with text parameter.
- `bizmodel2.vsh` - Fixed to use `playbook.new()` with text parameter.
- `bizmodel_complete.vsh` - Fixed to use `playbook.new()` with path parameter.
- `bizmodel_export.vsh` - Fixed to use `playbook.new()` with path parameter.
- `bizmodel_full.vsh` - Fixed to use `playbook.new()` with path parameter.
- `costs.vsh` - Fixed to use `playbook.new()` with text parameter.
- `funding.vsh` - Fixed to use `playbook.new()` with text parameter.
- `hr.vsh` - Fixed to use `playbook.new()` with text parameter.

## Previous Issues
All examples had issues with the `bizmodel.play()` function:

1. Unknown field (`heroscript` or `heroscript_path`) in struct literal of type `PlayBook`.
2. Reference field `PlayBook.session` must be initialized.
3. Function `bizmodel.play` parameter `plbook` is `mut`, so it requires `mut PlayBook{...}` instead.

## Solution Applied
All examples have been fixed by using the `playbook.new()` function to create a properly initialized PlayBook:

For examples with heroscript text:
```v
// Create a new playbook with the heroscript text
mut pb := playbook.new(text: heroscript)!

// Play the bizmodel actions
bizmodel.play(mut pb)!

// Get the bizmodel and print it
mut bm := bizmodel.get('test')!
```

For examples with heroscript path:
```v
// Create a new playbook with the heroscript path
mut pb := playbook.new(path: heroscript_path)!

// Play the bizmodel actions
bizmodel.play(mut pb)!
```

## Environment Setup
- Tests were performed with V language version 0.4.11 a11de72
- Redis server was running during tests
- All tests were executed from the `/workspace/project/herolib/examples/biztools` directory