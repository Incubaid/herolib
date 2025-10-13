# Code Tools

This directory contains various utilities and tools for code development.

## Available Tools

* `utils.v`: General utility functions.
* `vvet.v`: V language vetting tool.
* `vtest.v`: V language testing tool.

## Usage Examples

### Vetting Vlang Code with `vvet.v`

To vet your Vlang code for common issues and best practices, you can use the `vvet.v` tool.

```v
import incubaid.herolib.core.develop.codetools { list_v_files }
v run lib/develop/codetools/vvet.v your_file.v
```

### Testing Vlang Code with `vtest.v`

```v
import incubaid.herolib.core.de.vlang_utils { list_v_files }
v run lib/develop/codetools/vtest.v your_test_file.v
To run tests for your Vlang code, use the `vtest.v` tool.

```bash
v run lib/develop/codetools/vtest.v your_test_file.v
```

### Using Utility Functions from `utils.v`

The `utils.v` file contains various helper functions. You can import and use them in your Vlang projects.

```v
module main

import lib.develop.codetools.utils

fn main() {
    // Example usage of a utility function
    println(utils.greet("World"))
}
