# how to run the vshell example scripts

this is how we want example scripts to be, see the first line

```v
#!/usr/bin/env -S v -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib...

```

the files are in ~/code/github/freeflowuniverse/herolib/examples for herolib

## important instructions

- never use fn main() in a .vsh script
- always use the top line as in example above
- these scripts can be executed as is but can also use vrun $pathOfFile
