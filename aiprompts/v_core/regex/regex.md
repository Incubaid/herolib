# module regex


## Contents
- [Constants](#Constants)
- [new](#new)
- [regex_base](#regex_base)
- [regex_opt](#regex_opt)
- [FnLog](#FnLog)
- [FnReplace](#FnReplace)
- [FnValidator](#FnValidator)
- [RE](#RE)
  - [compile_opt](#compile_opt)
  - [find](#find)
  - [find_all](#find_all)
  - [find_all_str](#find_all_str)
  - [find_from](#find_from)
  - [get_code](#get_code)
  - [get_group_bounds_by_id](#get_group_bounds_by_id)
  - [get_group_bounds_by_name](#get_group_bounds_by_name)
  - [get_group_by_id](#get_group_by_id)
  - [get_group_by_name](#get_group_by_name)
  - [get_group_list](#get_group_list)
  - [get_query](#get_query)
  - [match_base](#match_base)
  - [match_string](#match_string)
  - [matches_string](#matches_string)
  - [replace](#replace)
  - [replace_by_fn](#replace_by_fn)
  - [replace_n](#replace_n)
  - [replace_simple](#replace_simple)
  - [reset](#reset)
  - [split](#split)
- [Re_group](#Re_group)

## Constants
```v
const v_regex_version = '1.0 alpha' // regex module version
```

[[Return to contents]](#Contents)

```v
const max_code_len = 256 // default small base code len for the regex programs
```

[[Return to contents]](#Contents)

```v
const max_quantifier = 1073741824 // default max repetitions allowed for the quantifiers = 2^30
```

[[Return to contents]](#Contents)

```v
const spaces = [` `, `\t`, `\n`, `\r`, `\v`, `\f`]
```

spaces chars (here only westerns!!) TODO: manage all the spaces from unicode

[[Return to contents]](#Contents)

```v
const new_line_list = [`\n`, `\r`]
```

new line chars for now only '\n'

[[Return to contents]](#Contents)

```v
const no_match_found = -1
```

Results

[[Return to contents]](#Contents)

```v
const compile_ok = 0 // the regex string compiled, all ok
```

Errors

[[Return to contents]](#Contents)

```v
const err_char_unknown = -2 // the char used is unknow to the system
```

[[Return to contents]](#Contents)

```v
const err_undefined = -3 // the compiler symbol is undefined
```

[[Return to contents]](#Contents)

```v
const err_internal_error = -4 // Bug in the regex system!!
```

[[Return to contents]](#Contents)

```v
const err_cc_alloc_overflow = -5 // memory for char class full!!
```

[[Return to contents]](#Contents)

```v
const err_syntax_error = -6 // syntax error in regex compiling
```

[[Return to contents]](#Contents)

```v
const err_groups_overflow = -7 // max number of groups reached
```

[[Return to contents]](#Contents)

```v
const err_groups_max_nested = -8 // max number of nested group reached
```

[[Return to contents]](#Contents)

```v
const err_group_not_balanced = -9 // group not balanced
```

[[Return to contents]](#Contents)

```v
const err_group_qm_notation = -10 // group invalid notation
```

[[Return to contents]](#Contents)

```v
const err_invalid_or_with_cc = -11 // invalid or on two consecutive char class
```

[[Return to contents]](#Contents)

```v
const err_neg_group_quantifier = -12 // negation groups can not have quantifier
```

[[Return to contents]](#Contents)

```v
const err_consecutive_dots = -13
```

[[Return to contents]](#Contents)

```v
const f_nl = 0x00000001 // end the match when find a new line symbol
```



[[Return to contents]](#Contents)

```v
const f_ms = 0x00000002 // match true only if the match is at the start of the string
```

[[Return to contents]](#Contents)

```v
const f_me = 0x00000004 // match true only if the match is at the end of the string
```

[[Return to contents]](#Contents)

```v
const f_efm = 0x00000100 // exit on first token matched, used by search
```

[[Return to contents]](#Contents)

```v
const f_bin = 0x00000200 // work only on bytes, ignore utf-8
```

[[Return to contents]](#Contents)

```v
const f_src = 0x00020000
```

behaviour modifier flags

[[Return to contents]](#Contents)

## new
```v
fn new() RE
```

new create a RE of small size, usually sufficient for ordinary use

[[Return to contents]](#Contents)

## regex_base
```v
fn regex_base(pattern string) (RE, int, int)
```

regex_base returns a regex object (`RE`) generated from `pattern` string and detailed information in re_err, err_pos, if an error occurred.

[[Return to contents]](#Contents)

## regex_opt
```v
fn regex_opt(pattern string) !RE
```

regex_opt create new RE object from RE pattern string

[[Return to contents]](#Contents)

## FnLog
```v
type FnLog = fn (string)
```

Log function prototype

[[Return to contents]](#Contents)

## FnReplace
```v
type FnReplace = fn (re RE, in_txt string, start int, end int) string
```

type of function used for custom replace in_txt  source text start   index of the start of the match in in_txt end     index of the end   of the match in in_txt the match is in in_txt[start..end]

[[Return to contents]](#Contents)

## FnValidator
```v
type FnValidator = fn (u8) bool
```



[[Return to contents]](#Contents)

## RE
```v
struct RE {
pub mut:
	prog     []Token
	prog_len int // regex program len
	// char classes storage
	cc       []CharClass // char class list
	cc_index int         // index
	// groups
	group_count      int   // number of groups in this regex struct
	groups           []int // groups index results
	group_max_nested int = 3 // max nested group
	group_max        int = 8 // max allowed number of different groups

	state_list []StateObj

	group_csave_flag bool  // flag to enable continuous saving
	group_csave      []int //= []int{}  // groups continuous save list

	group_map map[string]int // groups names map

	group_stack []int
	group_data  []int
	// flags
	flag int // flag for optional parameters
	// Debug/log
	debug    int // enable in order to have the unroll of the code 0 = NO_DEBUG, 1 = LIGHT 2 = VERBOSE
	log_func FnLog = simple_log // log function, can be customized by the user
	query    string // query string
}
```

[[Return to contents]](#Contents)

## compile_opt
```v
fn (mut re RE) compile_opt(pattern string) !
```

compile_opt compile RE pattern string

[[Return to contents]](#Contents)

## find
```v
fn (mut re RE) find(in_txt string) (int, int)
```

find try to find the first match in the input string

[[Return to contents]](#Contents)

## find_all
```v
fn (mut re RE) find_all(in_txt string) []int
```

find_all find all the non overlapping occurrences of the match pattern and return the start and end index of the match

Usage:
```v
blurb := 'foobar boo steelbar toolbox foot tooooot'
mut re := regex.regex_opt('f|t[eo]+')?
res := re.find_all(blurb) // [0, 3, 12, 15, 20, 23, 28, 31, 33, 39]
```


[[Return to contents]](#Contents)

## find_all_str
```v
fn (mut re RE) find_all_str(in_txt string) []string
```

find_all_str find all the non overlapping occurrences of the match pattern, return a string list

[[Return to contents]](#Contents)

## find_from
```v
fn (mut re RE) find_from(in_txt string, start int) (int, int)
```

find try to find the first match in the input string strarting from start index

[[Return to contents]](#Contents)

## get_code
```v
fn (re &RE) get_code() string
```

get_code return the compiled code as regex string, note: may be different from the source!

[[Return to contents]](#Contents)

## get_group_bounds_by_id
```v
fn (re &RE) get_group_bounds_by_id(group_id int) (int, int)
```

get_group_by_id get a group boundaries by its id

[[Return to contents]](#Contents)

## get_group_bounds_by_name
```v
fn (re &RE) get_group_bounds_by_name(group_name string) (int, int)
```

get_group_bounds_by_name get a group boundaries by its name

[[Return to contents]](#Contents)

## get_group_by_id
```v
fn (re &RE) get_group_by_id(in_txt string, group_id int) string
```

get_group_by_id get a group string by its id

[[Return to contents]](#Contents)

## get_group_by_name
```v
fn (re &RE) get_group_by_name(in_txt string, group_name string) string
```

get_group_by_name get a group boundaries by its name

[[Return to contents]](#Contents)

## get_group_list
```v
fn (re &RE) get_group_list() []Re_group
```

get_group_list return a list of Re_group for the found groups

[[Return to contents]](#Contents)

## get_query
```v
fn (re &RE) get_query() string
```

get_query return a string with a reconstruction of the query starting from the regex program code

[[Return to contents]](#Contents)

## match_base
```v
fn (mut re RE) match_base(in_txt &u8, in_txt_len int) (int, int)
```

[[Return to contents]](#Contents)

## match_string
```v
fn (re &RE) match_string(in_txt string) (int, int)
```

match_string Match the pattern with the in_txt string

[[Return to contents]](#Contents)

## matches_string
```v
fn (re &RE) matches_string(in_txt string) bool
```

matches_string Checks if the pattern matches the in_txt string

[[Return to contents]](#Contents)

## replace
```v
fn (mut re RE) replace(in_txt string, repl_str string) string
```

replace return a string where the matches are replaced with the repl_str string, this function supports groups in the replace string

[[Return to contents]](#Contents)

## replace_by_fn
```v
fn (mut re RE) replace_by_fn(in_txt string, repl_fn FnReplace) string
```

replace_by_fn return a string where the matches are replaced with the string from the repl_fn callback function

[[Return to contents]](#Contents)

## replace_n
```v
fn (mut re RE) replace_n(in_txt string, repl_str string, count int) string
```

replace_n return a string where the first count matches are replaced with the repl_str string, if count is > 0 the replace began from the start of the string toward the end if count is < 0 the replace began from the end of the string toward the start if count is 0 do nothing

[[Return to contents]](#Contents)

## replace_simple
```v
fn (mut re RE) replace_simple(in_txt string, repl string) string
```

replace_simple return a string where the matches are replaced with the replace string

[[Return to contents]](#Contents)

## reset
```v
fn (mut re RE) reset()
```

Reset RE object

[[Return to contents]](#Contents)

## split
```v
fn (mut re RE) split(in_txt string) []string
```

split returns the sections of string around the regex

Usage:
```v
blurb := 'foobar boo steelbar toolbox foot tooooot'
mut re := regex.regex_opt('f|t[eo]+')?
res := re.split(blurb) // ['bar boo s', 'lbar ', 'lbox ', 't ', 't']
```


[[Return to contents]](#Contents)

## Re_group
```v
struct Re_group {
pub:
	start int = -1
	end   int = -1
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:19:51
