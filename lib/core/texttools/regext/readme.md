# regex

## basic regex utilities

### escape_regex_chars

Escapes special regex metacharacters in a string to make it safe for use in regex patterns.

```v
import incubaid.herolib.core.texttools.regext

escaped := regext.escape_regex_chars("file.txt")
// Result: "file\.txt"

// Use in regex patterns:
safe_search := regext.escape_regex_chars("[test]")
// Result: "\[test\]"
```

**Special characters escaped**: `. ^ $ * + ? { } [ ] \ | ( )`

### wildcard_to_regex

Converts simple wildcard patterns to regex patterns for flexible file matching.

**Conversion rules:**
- `*` becomes `.*` (matches any sequence of characters)
- Literal text is escaped (special regex characters are escaped)
- Patterns without `*` match as substrings anywhere

```v
import incubaid.herolib.core.texttools.regext

// Match files ending with .txt
pattern1 := regext.wildcard_to_regex("*.txt")
// Result: ".*\.txt"

// Match anything starting with test
pattern2 := regext.wildcard_to_regex("test*")
// Result: "test.*"

// Match anything containing 'config' (no wildcard)
pattern3 := regext.wildcard_to_regex("config")
// Result: ".*config.*"

// Complex pattern with special chars
pattern4 := regext.wildcard_to_regex("src/*.v")
// Result: "src/.*\.v"

// Multiple wildcards
pattern5 := regext.wildcard_to_regex("*test*file*")
// Result: ".*test.*file.*"
```

## regex replacer

Tool to flexibly replace elements in file(s) or text.

```golang
import incubaid.herolib.core.texttools.regext
text := '

this is test_1 SomeTest
this is Test 1 SomeTest

need to replace TF to ThreeFold
need to replace ThreeFold0 to ThreeFold
need to replace ThreeFold1 to ThreeFold

'

text_out := '

this is TTT SomeTest
this is TTT SomeTest

need to replace ThreeFold to ThreeFold
need to replace ThreeFold to ThreeFold
need to replace ThreeFold to ThreeFold

'

mut ri := regext.regex_instructions_new()
ri.add(['TF:ThreeFold0:ThreeFold1:ThreeFold']) or { panic(err) }
ri.add_item('test_1', 'TTT') or { panic(err) }
ri.add_item('^Stest 1', 'TTT') or { panic(err) } //will be case insensitive search

mut text_out2 := ri.replace(text: text, dedent: true) or { panic(err) }

//pub struct ReplaceDirArgs {
//pub mut:
// path       string
// extensions []string
// dryrun     bool
//}
// if dryrun is true then will not replace but just show
ri.replace_in_dir(path:"/tmp/mypath",extensions:["md"])!

```

## Testing

Run regex conversion tests:

```bash
vtest ~/code/github/incubaid/herolib/lib/core/texttools/regext/regex_convert_test.v
```
