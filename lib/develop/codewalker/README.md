# CodeWalker Module

The CodeWalker module provides functionality to walk through directories and create a map of files with their content. It's particularly useful for processing code directories while respecting gitignore patterns.

## Features

- Walk through directories recursively
- Respect gitignore patterns to exclude files
- Store file content in memory
- Export files back to a directory structure

## Usage

```v
import freeflowuniverse.herolib.lib.lang.codewalker

mut cw := codewalker.new('/tmp/adir')!

// Get content of a specific file
content := cw.filemap.get('path/to/file.txt')!

// return output again
cw.filemap.content()

// Export all files to a destination directory
cw.filemap.export('/tmp/exported_files')!

```

### format of filemap

## full files

```

text before will be ignored

===FILE:filename===
code
===FILE:filename===
code
===END===

text behind will be ignored

```

## files with changes

```

text before will be ignored

===FILECHANGE:filename===
code
===FILECHANGE:filename===
code
===END===

text behind will be ignored

```

FILECHANGE and FILE can be mixed, in FILE it means we have full content otherwise only changed content e.g. a method or s struct and then we need to use morph to change it
