# module builtin


## Contents
- [Constants](#Constants)
- [C.android_print](#C.android_print)
- [arguments](#arguments)
- [at_exit](#at_exit)
- [c_error_number_str](#c_error_number_str)
- [compare_strings](#compare_strings)
- [copy](#copy)
- [cstring_to_vstring](#cstring_to_vstring)
- [eprint](#eprint)
- [eprintln](#eprintln)
- [error](#error)
- [error_with_code](#error_with_code)
- [exit](#exit)
- [f32_abs](#f32_abs)
- [f32_max](#f32_max)
- [f32_min](#f32_min)
- [f64_abs](#f64_abs)
- [f64_max](#f64_max)
- [f64_min](#f64_min)
- [flush_stderr](#flush_stderr)
- [flush_stdout](#flush_stdout)
- [free](#free)
- [gc_check_leaks](#gc_check_leaks)
- [gc_collect](#gc_collect)
- [gc_disable](#gc_disable)
- [gc_enable](#gc_enable)
- [gc_get_warn_proc](#gc_get_warn_proc)
- [gc_heap_usage](#gc_heap_usage)
- [gc_is_enabled](#gc_is_enabled)
- [gc_memory_use](#gc_memory_use)
- [gc_set_warn_proc](#gc_set_warn_proc)
- [get_str_intp_u32_format](#get_str_intp_u32_format)
- [get_str_intp_u64_format](#get_str_intp_u64_format)
- [input_character](#input_character)
- [int_max](#int_max)
- [int_min](#int_min)
- [isnil](#isnil)
- [malloc](#malloc)
- [malloc_noscan](#malloc_noscan)
- [malloc_uncollectable](#malloc_uncollectable)
- [memdup](#memdup)
- [memdup_align](#memdup_align)
- [memdup_noscan](#memdup_noscan)
- [memdup_uncollectable](#memdup_uncollectable)
- [panic](#panic)
- [panic_error_number](#panic_error_number)
- [panic_lasterr](#panic_lasterr)
- [panic_n](#panic_n)
- [panic_n2](#panic_n2)
- [panic_option_not_set](#panic_option_not_set)
- [panic_result_not_set](#panic_result_not_set)
- [print](#print)
- [print_backtrace](#print_backtrace)
- [print_backtrace_skipping_top_frames](#print_backtrace_skipping_top_frames)
- [print_character](#print_character)
- [println](#println)
- [proc_pidpath](#proc_pidpath)
- [ptr_str](#ptr_str)
- [realloc_data](#realloc_data)
- [reuse_data_as_string](#reuse_data_as_string)
- [reuse_string_as_data](#reuse_string_as_data)
- [str_intp](#str_intp)
- [str_intp_g32](#str_intp_g32)
- [str_intp_g64](#str_intp_g64)
- [str_intp_rune](#str_intp_rune)
- [str_intp_sq](#str_intp_sq)
- [str_intp_sub](#str_intp_sub)
- [string_from_wide](#string_from_wide)
- [string_from_wide2](#string_from_wide2)
- [string_to_ansi_not_null_terminated](#string_to_ansi_not_null_terminated)
- [tos](#tos)
- [tos2](#tos2)
- [tos3](#tos3)
- [tos4](#tos4)
- [tos5](#tos5)
- [tos_clone](#tos_clone)
- [unbuffer_stdout](#unbuffer_stdout)
- [utf32_decode_to_buffer](#utf32_decode_to_buffer)
- [utf32_to_str](#utf32_to_str)
- [utf32_to_str_no_malloc](#utf32_to_str_no_malloc)
- [utf8_char_len](#utf8_char_len)
- [utf8_str_visible_length](#utf8_str_visible_length)
- [v_realloc](#v_realloc)
- [vcalloc](#vcalloc)
- [vcalloc_noscan](#vcalloc_noscan)
- [vcurrent_hash](#vcurrent_hash)
- [vmemcmp](#vmemcmp)
- [vmemcpy](#vmemcpy)
- [vmemmove](#vmemmove)
- [vmemset](#vmemset)
- [vstrlen](#vstrlen)
- [vstrlen_char](#vstrlen_char)
- [wide_to_ansi](#wide_to_ansi)
- [IError](#IError)
  - [free](#free)
  - [str](#str)
- [C.intptr_t](#C.intptr_t)
- [FnExitCb](#FnExitCb)
- [FnGC_WarnCB](#FnGC_WarnCB)
- [MessageError](#MessageError)
  - [str](#str)
  - [msg](#msg)
  - [code](#code)
  - [free](#free)
- [[]rune](#[]rune)
  - [string](#string)
- [[]string](#[]string)
  - [free](#free)
  - [join](#join)
  - [join_lines](#join_lines)
  - [sort_by_len](#sort_by_len)
  - [sort_ignore_case](#sort_ignore_case)
  - [str](#str)
- [[]u8](#[]u8)
  - [byterune](#byterune)
  - [bytestr](#bytestr)
  - [hex](#hex)
  - [utf8_to_utf32](#utf8_to_utf32)
- [bool](#bool)
  - [str](#str)
- [byte](#byte)
- [byteptr](#byteptr)
  - [str](#str)
  - [vbytes](#vbytes)
  - [vstring](#vstring)
  - [vstring_literal](#vstring_literal)
  - [vstring_literal_with_len](#vstring_literal_with_len)
  - [vstring_with_len](#vstring_with_len)
- [chan](#chan)
  - [close](#close)
  - [try_pop](#try_pop)
  - [try_push](#try_push)
- [char](#char)
  - [str](#str)
  - [vstring](#vstring)
  - [vstring_literal](#vstring_literal)
  - [vstring_literal_with_len](#vstring_literal_with_len)
  - [vstring_with_len](#vstring_with_len)
- [charptr](#charptr)
  - [str](#str)
  - [vstring](#vstring)
  - [vstring_literal](#vstring_literal)
  - [vstring_literal_with_len](#vstring_literal_with_len)
  - [vstring_with_len](#vstring_with_len)
- [f32](#f32)
  - [str](#str)
  - [strg](#strg)
  - [strsci](#strsci)
  - [strlong](#strlong)
  - [eq_epsilon](#eq_epsilon)
- [f64](#f64)
  - [str](#str)
  - [strg](#strg)
  - [strsci](#strsci)
  - [strlong](#strlong)
  - [eq_epsilon](#eq_epsilon)
- [float-literal](#float literal)
  - [str](#str)
- [i16](#i16)
  - [str](#str)
  - [hex](#hex)
  - [hex_full](#hex_full)
- [i32](#i32)
  - [str](#str)
- [i64](#i64)
  - [str](#str)
  - [hex](#hex)
  - [hex_full](#hex_full)
- [i8](#i8)
  - [str](#str)
  - [hex](#hex)
  - [hex_full](#hex_full)
- [int](#int)
  - [hex_full](#hex_full)
  - [str](#str)
  - [hex](#hex)
  - [hex2](#hex2)
- [int-literal](#int literal)
  - [str](#str)
  - [hex](#hex)
  - [hex_full](#hex_full)
- [isize](#isize)
  - [str](#str)
- [none](#none)
  - [str](#str)
- [rune](#rune)
  - [str](#str)
  - [repeat](#repeat)
  - [bytes](#bytes)
  - [length_in_bytes](#length_in_bytes)
  - [to_upper](#to_upper)
  - [to_lower](#to_lower)
  - [to_title](#to_title)
- [u16](#u16)
  - [str](#str)
  - [hex](#hex)
  - [hex_full](#hex_full)
- [u32](#u32)
  - [str](#str)
  - [hex](#hex)
  - [hex_full](#hex_full)
- [u64](#u64)
  - [str](#str)
  - [hex](#hex)
  - [hex_full](#hex_full)
- [u8](#u8)
  - [ascii_str](#ascii_str)
  - [free](#free)
  - [hex](#hex)
  - [hex_full](#hex_full)
  - [is_alnum](#is_alnum)
  - [is_bin_digit](#is_bin_digit)
  - [is_capital](#is_capital)
  - [is_digit](#is_digit)
  - [is_hex_digit](#is_hex_digit)
  - [is_letter](#is_letter)
  - [is_oct_digit](#is_oct_digit)
  - [is_space](#is_space)
  - [repeat](#repeat)
  - [str](#str)
  - [str_escaped](#str_escaped)
  - [vbytes](#vbytes)
  - [vstring](#vstring)
  - [vstring_literal](#vstring_literal)
  - [vstring_literal_with_len](#vstring_literal_with_len)
  - [vstring_with_len](#vstring_with_len)
- [usize](#usize)
  - [str](#str)
- [voidptr](#voidptr)
  - [hex_full](#hex_full)
  - [str](#str)
  - [vbytes](#vbytes)
- [ArrayFlags](#ArrayFlags)
- [AttributeKind](#AttributeKind)
- [ChanState](#ChanState)
- [StrIntpType](#StrIntpType)
  - [str](#str)
- [C.DIR](#C.DIR)
- [C.FILE](#C.FILE)
- [C.GC_stack_base](#C.GC_stack_base)
- [C.IError](#C.IError)
- [C.SRWLOCK](#C.SRWLOCK)
- [C.SYSTEM_INFO](#C.SYSTEM_INFO)
- [EnumData](#EnumData)
- [Error](#Error)
  - [msg](#msg)
  - [code](#code)
- [FieldData](#FieldData)
- [FunctionData](#FunctionData)
- [GCHeapUsage](#GCHeapUsage)
- [MethodParam](#MethodParam)
- [RunesIterator](#RunesIterator)
  - [next](#next)
- [SortedMap](#SortedMap)
  - [delete](#delete)
  - [keys](#keys)
  - [free](#free)
  - [print](#print)
- [StrIntpCgenData](#StrIntpCgenData)
- [StrIntpData](#StrIntpData)
- [StrIntpMem](#StrIntpMem)
- [VAssertMetaInfo](#VAssertMetaInfo)
  - [free](#free)
- [VAttribute](#VAttribute)
- [VContext](#VContext)
- [VariantData](#VariantData)
- [WrapConfig](#WrapConfig)
- [array](#array)
  - [ensure_cap](#ensure_cap)
  - [repeat](#repeat)
  - [repeat_to_depth](#repeat_to_depth)
  - [insert](#insert)
  - [prepend](#prepend)
  - [delete](#delete)
  - [delete_many](#delete_many)
  - [clear](#clear)
  - [reset](#reset)
  - [trim](#trim)
  - [drop](#drop)
  - [first](#first)
  - [last](#last)
  - [pop_left](#pop_left)
  - [pop](#pop)
  - [delete_last](#delete_last)
  - [clone](#clone)
  - [clone_to_depth](#clone_to_depth)
  - [push_many](#push_many)
  - [reverse_in_place](#reverse_in_place)
  - [reverse](#reverse)
  - [free](#free)
  - [filter](#filter)
  - [any](#any)
  - [count](#count)
  - [all](#all)
  - [map](#map)
  - [sort](#sort)
  - [sorted](#sorted)
  - [sort_with_compare](#sort_with_compare)
  - [sorted_with_compare](#sorted_with_compare)
  - [contains](#contains)
  - [index](#index)
  - [grow_cap](#grow_cap)
  - [grow_len](#grow_len)
  - [pointers](#pointers)
- [map](#map)
  - [move](#move)
  - [clear](#clear)
  - [reserve](#reserve)
  - [delete](#delete)
  - [keys](#keys)
  - [values](#values)
  - [clone](#clone)
  - [free](#free)
- [string](#string)
  - [after](#after)
  - [after_char](#after_char)
  - [all_after](#all_after)
  - [all_after_first](#all_after_first)
  - [all_after_last](#all_after_last)
  - [all_before](#all_before)
  - [all_before_last](#all_before_last)
  - [before](#before)
  - [bool](#bool)
  - [bytes](#bytes)
  - [camel_to_snake](#camel_to_snake)
  - [capitalize](#capitalize)
  - [clone](#clone)
  - [compare](#compare)
  - [contains](#contains)
  - [contains_any](#contains_any)
  - [contains_any_substr](#contains_any_substr)
  - [contains_only](#contains_only)
  - [contains_u8](#contains_u8)
  - [count](#count)
  - [ends_with](#ends_with)
  - [expand_tabs](#expand_tabs)
  - [f32](#f32)
  - [f64](#f64)
  - [fields](#fields)
  - [find_between](#find_between)
  - [free](#free)
  - [hash](#hash)
  - [hex](#hex)
  - [i16](#i16)
  - [i32](#i32)
  - [i64](#i64)
  - [i8](#i8)
  - [indent_width](#indent_width)
  - [index](#index)
  - [index_after](#index_after)
  - [index_after_](#index_after_)
  - [index_any](#index_any)
  - [index_u8](#index_u8)
  - [int](#int)
  - [is_ascii](#is_ascii)
  - [is_bin](#is_bin)
  - [is_blank](#is_blank)
  - [is_capital](#is_capital)
  - [is_hex](#is_hex)
  - [is_identifier](#is_identifier)
  - [is_int](#is_int)
  - [is_lower](#is_lower)
  - [is_oct](#is_oct)
  - [is_pure_ascii](#is_pure_ascii)
  - [is_title](#is_title)
  - [is_upper](#is_upper)
  - [last_index](#last_index)
  - [last_index_u8](#last_index_u8)
  - [len_utf8](#len_utf8)
  - [limit](#limit)
  - [match_glob](#match_glob)
  - [normalize_tabs](#normalize_tabs)
  - [parse_int](#parse_int)
  - [parse_uint](#parse_uint)
  - [repeat](#repeat)
  - [replace](#replace)
  - [replace_char](#replace_char)
  - [replace_each](#replace_each)
  - [replace_once](#replace_once)
  - [reverse](#reverse)
  - [rsplit](#rsplit)
  - [rsplit_any](#rsplit_any)
  - [rsplit_nth](#rsplit_nth)
  - [rsplit_once](#rsplit_once)
  - [runes](#runes)
  - [runes_iterator](#runes_iterator)
  - [snake_to_camel](#snake_to_camel)
  - [split](#split)
  - [split_any](#split_any)
  - [split_by_space](#split_by_space)
  - [split_into_lines](#split_into_lines)
  - [split_n](#split_n)
  - [split_nth](#split_nth)
  - [split_once](#split_once)
  - [starts_with](#starts_with)
  - [starts_with_capital](#starts_with_capital)
  - [str](#str)
  - [strip_margin](#strip_margin)
  - [strip_margin_custom](#strip_margin_custom)
  - [substr](#substr)
  - [substr_ni](#substr_ni)
  - [substr_unsafe](#substr_unsafe)
  - [substr_with_check](#substr_with_check)
  - [title](#title)
  - [to_lower](#to_lower)
  - [to_lower_ascii](#to_lower_ascii)
  - [to_upper](#to_upper)
  - [to_upper_ascii](#to_upper_ascii)
  - [to_wide](#to_wide)
  - [trim](#trim)
  - [trim_indent](#trim_indent)
  - [trim_indexes](#trim_indexes)
  - [trim_left](#trim_left)
  - [trim_right](#trim_right)
  - [trim_space](#trim_space)
  - [trim_space_left](#trim_space_left)
  - [trim_space_right](#trim_space_right)
  - [trim_string_left](#trim_string_left)
  - [trim_string_right](#trim_string_right)
  - [u16](#u16)
  - [u32](#u32)
  - [u64](#u64)
  - [u8](#u8)
  - [u8_array](#u8_array)
  - [uncapitalize](#uncapitalize)
  - [utf32_code](#utf32_code)
  - [wrap](#wrap)

## Constants
```v
const max_i16 = i16(32767)
```

[[Return to contents]](#Contents)

```v
const min_u8 = u8(0)
```

[[Return to contents]](#Contents)

```v
const max_u8 = u8(255)
```

[[Return to contents]](#Contents)

```v
const min_int = int(-2147483648)
```

[[Return to contents]](#Contents)

```v
const max_int = int(2147483647)
```

[[Return to contents]](#Contents)

```v
const min_i64 = i64(-9223372036854775807 - 1)
```

-9223372036854775808 is wrong, because C compilers parse literal values without sign first, and 9223372036854775808 overflows i64, hence the consecutive subtraction by 1

[[Return to contents]](#Contents)

```v
const max_u16 = u16(65535)
```

[[Return to contents]](#Contents)

```v
const min_u16 = u16(0)
```

[[Return to contents]](#Contents)

```v
const min_i32 = i32(-2147483648)
```

[[Return to contents]](#Contents)

```v
const si_g32_code = '0xfe0e'
```

[[Return to contents]](#Contents)

```v
const max_i8 = i8(127)
```

[[Return to contents]](#Contents)

```v
const max_u64 = u64(18446744073709551615)
```

[[Return to contents]](#Contents)

```v
const max_i32 = i32(2147483647)
```

[[Return to contents]](#Contents)

```v
const max_i64 = i64(9223372036854775807)
```

[[Return to contents]](#Contents)

```v
const min_i8 = i8(-128)
```

[[Return to contents]](#Contents)

```v
const min_u64 = u64(0)
```

[[Return to contents]](#Contents)

```v
const min_i16 = i16(-32768)
```

[[Return to contents]](#Contents)

```v
const si_s_code = '0xfe10'
```

The consts here are utilities for the compiler's "auto_str_methods.v". They are used to substitute old _STR calls.

Fixme: this const is not released from memory => use a precalculated string const for now. si_s_code = "0x" + int(StrIntpType.si_s).hex() // code for a simple string.

[[Return to contents]](#Contents)

```v
const min_u32 = u32(0)
```

[[Return to contents]](#Contents)

```v
const si_g64_code = '0xfe0f'
```

[[Return to contents]](#Contents)

```v
const max_u32 = u32(4294967295)
```

[[Return to contents]](#Contents)

## C.android_print
```v
fn C.android_print(fstream voidptr, format &char, opt ...voidptr)
```

used by Android for (e)println to output to the Android log system / logcat

[[Return to contents]](#Contents)

## arguments
```v
fn arguments() []string
```

arguments returns the command line arguments, used for starting the current program as a V array of strings. The first string in the array (index 0), is the name of the program, used for invoking the program. The second string in the array (index 1), if it exists, is the first argument to the program, etc. For example, if you started your program as `myprogram -option`, then arguments() will return ['myprogram', '-option'].

Note: if you `v run file.v abc def`, then arguments() will return ['file', 'abc', 'def'], or ['file.exe', 'abc', 'def'] (on Windows).

[[Return to contents]](#Contents)

## at_exit
```v
fn at_exit(cb FnExitCb) !
```

at_exit registers a fn callback, that will be called at normal process termination. It returns an error, if the registration was not successful. The registered callback functions, will be called either via exit/1, or via return from the main program, in the reverse order of their registration. The same fn may be registered multiple times. Each callback fn will called once for each registration.

[[Return to contents]](#Contents)

## c_error_number_str
```v
fn c_error_number_str(errnum int) string
```

return a C-API error message matching to `errnum`

[[Return to contents]](#Contents)

## compare_strings
```v
fn compare_strings(a &string, b &string) int
```

compare_strings returns `-1` if `a < b`, `1` if `a > b` else `0`.

[[Return to contents]](#Contents)

## copy
```v
fn copy(mut dst []u8, src []u8) int
```

copy copies the `src` byte array elements to the `dst` byte array. The number of the elements copied is the minimum of the length of both arrays. Returns the number of elements copied.

Note: This is not an `array` method. It is a function that takes two arrays of bytes. See also: `arrays.copy`.

[[Return to contents]](#Contents)

## cstring_to_vstring
```v
fn cstring_to_vstring(const_s &char) string
```

cstring_to_vstring creates a new V string copy of the C style string, pointed by `s`. This function is most likely what you want to use when working with C style pointers to 0 terminated strings (i.e. `char*`). It is recommended to use it, unless you *do* understand the implications of tos/tos2/tos3/tos4/tos5 in terms of memory management and interactions with -autofree and `@[manualfree]`. It will panic, if the pointer `s` is 0.

[[Return to contents]](#Contents)

## eprint
```v
fn eprint(s string)
```

eprint prints a message to stderr. Both stderr and stdout are flushed.

[[Return to contents]](#Contents)

## eprintln
```v
fn eprintln(s string)
```

eprintln prints a message with a line end, to stderr. Both stderr and stdout are flushed.

[[Return to contents]](#Contents)

## error
```v
fn error(message string) IError
```

error returns a default error instance containing the error given in `message`.

Example
```v

f := fn (ouch bool) ! { if ouch { return error('an error occurred') } }; f(false)!

```

[[Return to contents]](#Contents)

## error_with_code
```v
fn error_with_code(message string, code int) IError
```

error_with_code returns a default error instance containing the given `message` and error `code`.

Example
```v

f := fn (ouch bool) ! { if ouch { return error_with_code('an error occurred', 1) } }; f(false)!

```

[[Return to contents]](#Contents)

## exit
```v
fn exit(code int)
```

exit terminates execution immediately and returns exit `code` to the shell.

[[Return to contents]](#Contents)

## f32_abs
```v
fn f32_abs(a f32) f32
```

f32_abs returns the absolute value of `a` as a `f32` value.

Example
```v

assert f32_abs(-2.0) == 2.0

```

[[Return to contents]](#Contents)

## f32_max
```v
fn f32_max(a f32, b f32) f32
```

f32_max returns the larger `f32` of input `a` and `b`.

Example
```v

assert f32_max(2.0,3.0) == 3.0

```

[[Return to contents]](#Contents)

## f32_min
```v
fn f32_min(a f32, b f32) f32
```

f32_min returns the smaller `f32` of input `a` and `b`.

Example
```v

assert f32_min(2.0,3.0) == 2.0

```

[[Return to contents]](#Contents)

## f64_abs
```v
fn f64_abs(a f64) f64
```

f64_abs returns the absolute value of `a` as a `f64` value.

Example
```v

assert f64_abs(-2.0) == f64(2.0)

```

[[Return to contents]](#Contents)

## f64_max
```v
fn f64_max(a f64, b f64) f64
```

f64_max returns the larger `f64` of input `a` and `b`.

Example
```v

assert f64_max(2.0,3.0) == 3.0

```

[[Return to contents]](#Contents)

## f64_min
```v
fn f64_min(a f64, b f64) f64
```

f64_min returns the smaller `f64` of input `a` and `b`.

Example
```v

assert f64_min(2.0,3.0) == 2.0

```

[[Return to contents]](#Contents)

## flush_stderr
```v
fn flush_stderr()
```

[[Return to contents]](#Contents)

## flush_stdout
```v
fn flush_stdout()
```

[[Return to contents]](#Contents)

## free
```v
fn free(ptr voidptr)
```

free allows for manually freeing memory allocated at the address `ptr`.

[[Return to contents]](#Contents)

## gc_check_leaks
```v
fn gc_check_leaks()
```

gc_check_leaks is useful for leak detection (it does an explicit garbage collections, but only when a program is compiled with `-gc boehm_leak`).

[[Return to contents]](#Contents)

## gc_collect
```v
fn gc_collect()
```

gc_collect explicitly performs a single garbage collection run. Note, that garbage collections, are done automatically, when needed in most cases, so usually you should NOT need to call gc_collect() often. Note that gc_collect() is a NOP with `-gc none`.

[[Return to contents]](#Contents)

## gc_disable
```v
fn gc_disable()
```

gc_disable explicitly disables the GC. Do not forget to enable it again by calling gc_enable(), when your program is otherwise idle, and can afford it. See also gc_enable() and gc_collect(). Note that gc_disable() is a NOP with `-gc none`.

[[Return to contents]](#Contents)

## gc_enable
```v
fn gc_enable()
```

gc_enable explicitly enables the GC. Note, that garbage collections are done automatically, when needed in most cases, and also that by default the GC is on, so you do not need to enable it. See also gc_disable() and gc_collect(). Note that gc_enable() is a NOP with `-gc none`.

[[Return to contents]](#Contents)

## gc_get_warn_proc
```v
fn gc_get_warn_proc() FnGC_WarnCB
```

gc_get_warn_proc returns the current callback fn, that will be used for printing GC warnings.

[[Return to contents]](#Contents)

## gc_heap_usage
```v
fn gc_heap_usage() GCHeapUsage
```

gc_heap_usage returns the info about heap usage.

[[Return to contents]](#Contents)

## gc_is_enabled
```v
fn gc_is_enabled() bool
```

gc_is_enabled() returns true, if the GC is enabled at runtime. See also gc_disable() and gc_enable().

[[Return to contents]](#Contents)

## gc_memory_use
```v
fn gc_memory_use() usize
```

gc_memory_use returns the total memory use in bytes by all allocated blocks.

[[Return to contents]](#Contents)

## gc_set_warn_proc
```v
fn gc_set_warn_proc(cb FnGC_WarnCB)
```

gc_set_warn_proc sets the callback fn, that will be used for printing GC warnings.

[[Return to contents]](#Contents)

## get_str_intp_u32_format
```v
fn get_str_intp_u32_format(fmt_type StrIntpType, in_width int, in_precision int, in_tail_zeros bool,
	in_sign bool, in_pad_ch u8, in_base int, in_upper_case bool) u32
```

convert from data format to compact u32

[[Return to contents]](#Contents)

## get_str_intp_u64_format
```v
fn get_str_intp_u64_format(fmt_type StrIntpType, in_width int, in_precision int, in_tail_zeros bool,
	in_sign bool, in_pad_ch u8, in_base int, in_upper_case bool) u64
```

convert from data format to compact u64

[[Return to contents]](#Contents)

## input_character
```v
fn input_character() int
```

input_character gives back a single character, read from the standard input. It returns -1 on error (when the input is finished (EOF), on a broken pipe etc).

[[Return to contents]](#Contents)

## int_max
```v
fn int_max(a int, b int) int
```

int_max returns the largest `int` of input `a` and `b`.

Example
```v

assert int_max(2,3) == 3

```

[[Return to contents]](#Contents)

## int_min
```v
fn int_min(a int, b int) int
```

int_min returns the smallest `int` of input `a` and `b`.

Example
```v

assert int_min(2,3) == 2

```

[[Return to contents]](#Contents)

## isnil
```v
fn isnil(v voidptr) bool
```

isnil returns true if an object is nil (only for C objects).

[[Return to contents]](#Contents)

## malloc
```v
fn malloc(n isize) &u8
```

malloc dynamically allocates a `n` bytes block of memory on the heap. malloc returns a `byteptr` pointing to the memory address of the allocated space. unlike the `calloc` family of functions - malloc will not zero the memory block.

[[Return to contents]](#Contents)

## malloc_noscan
```v
fn malloc_noscan(n isize) &u8
```

[[Return to contents]](#Contents)

## malloc_uncollectable
```v
fn malloc_uncollectable(n isize) &u8
```

malloc_uncollectable dynamically allocates a `n` bytes block of memory on the heap, which will NOT be garbage-collected (but its contents will).

[[Return to contents]](#Contents)

## memdup
```v
fn memdup(src voidptr, sz isize) voidptr
```

memdup dynamically allocates a `sz` bytes block of memory on the heap memdup then copies the contents of `src` into the allocated space and returns a pointer to the newly allocated space.

[[Return to contents]](#Contents)

## memdup_align
```v
fn memdup_align(src voidptr, sz isize, align isize) voidptr
```

memdup_align dynamically allocates a memory block of `sz` bytes on the heap, copies the contents from `src` into the allocated space, and returns a pointer to the newly allocated memory. The returned pointer is aligned to the specified `align` boundary.- `align` must be a power of two and at least 1
- `sz` must be non-negative
- The memory regions should not overlap


[[Return to contents]](#Contents)

## memdup_noscan
```v
fn memdup_noscan(src voidptr, sz isize) voidptr
```

[[Return to contents]](#Contents)

## memdup_uncollectable
```v
fn memdup_uncollectable(src voidptr, sz isize) voidptr
```

memdup_uncollectable dynamically allocates a `sz` bytes block of memory on the heap, which will NOT be garbage-collected (but its contents will). memdup_uncollectable then copies the contents of `src` into the allocated space and returns a pointer to the newly allocated space.

[[Return to contents]](#Contents)

## panic
```v
fn panic(s string)
```

panic prints a nice error message, then exits the process with exit code of 1. It also shows a backtrace on most platforms.

[[Return to contents]](#Contents)

## panic_error_number
```v
fn panic_error_number(basestr string, errnum int)
```

panic with a C-API error message matching `errnum`

[[Return to contents]](#Contents)

## panic_lasterr
```v
fn panic_lasterr(base string)
```

[[Return to contents]](#Contents)

## panic_n
```v
fn panic_n(s string, number1 i64)
```

panic_n prints an error message, followed by the given number, then exits the process with exit code of 1.

[[Return to contents]](#Contents)

## panic_n2
```v
fn panic_n2(s string, number1 i64, number2 i64)
```

panic_n2 prints an error message, followed by the given numbers, then exits the process with exit code of 1.

[[Return to contents]](#Contents)

## panic_option_not_set
```v
fn panic_option_not_set(s string)
```

panic_option_not_set is called by V, when you use option error propagation in your main function. It ends the program with a panic.

[[Return to contents]](#Contents)

## panic_result_not_set
```v
fn panic_result_not_set(s string)
```

panic_result_not_set is called by V, when you use result error propagation in your main function It ends the program with a panic.

[[Return to contents]](#Contents)

## print
```v
fn print(s string)
```

print prints a message to stdout. Note that unlike `eprint`, stdout is not automatically flushed.

[[Return to contents]](#Contents)

## print_backtrace
```v
fn print_backtrace()
```

print_backtrace shows a backtrace of the current call stack on stdout.

[[Return to contents]](#Contents)

## print_backtrace_skipping_top_frames
```v
fn print_backtrace_skipping_top_frames(xskipframes int) bool
```

print_backtrace_skipping_top_frames prints the backtrace skipping N top frames.

[[Return to contents]](#Contents)

## print_character
```v
fn print_character(ch u8) int
```

print_character writes the single character `ch` to the standard output. It returns -1 on error (when the output is closed, on a broken pipe, etc).

Note: this function does not allocate memory, unlike `print(ch.ascii_str())` which does, and is thus cheaper to call, which is important, if you have to output many characters one by one. If you instead want to print entire strings at once, use `print(your_string)`.

[[Return to contents]](#Contents)

## println
```v
fn println(s string)
```

println prints a message with a line end, to stdout. Note that unlike `eprintln`, stdout is not automatically flushed.

[[Return to contents]](#Contents)

## proc_pidpath
```v
fn proc_pidpath(int, voidptr, int) int
```

<libproc.h>

[[Return to contents]](#Contents)

## ptr_str
```v
fn ptr_str(ptr voidptr) string
```

ptr_str returns a string with the address of `ptr`.

[[Return to contents]](#Contents)

## realloc_data
```v
fn realloc_data(old_data &u8, old_size int, new_size int) &u8
```

realloc_data resizes the memory block pointed by `old_data` to `new_size` bytes. `old_data` must be a pointer to an existing memory block, previously allocated with `malloc` or `vcalloc`, of size `old_data`. realloc_data returns a pointer to the new location of the block.

Note: if you know the old data size, it is preferable to call `realloc_data`, instead of `v_realloc`, at least during development, because `realloc_data` can make debugging easier, when you compile your program with `-d debug_realloc`.

[[Return to contents]](#Contents)

## reuse_data_as_string
```v
fn reuse_data_as_string(buffer []u8) string
```

reuse_data_as_string provides a way to treat the memory of a []u8 `buffer` as a string value. It does not allocate or copy the memory block for the `buffer`, but instead creates a string descriptor, that will point to the same memory as the input. The intended use of that function, is to allow calling string search methods (defined on string), on []u8 values too, without having to copy/allocate by calling .bytestr() (that can be too slow and unnecessary in loops).

Note: unlike normal V strings, the return value *is not* guaranteed to have a terminating `0` byte, since this function does not allocate or modify the input in any way. This is not a problem usually, since V methods and functions do not require it, but be careful, if you want to pass that string to call a C. function, that expects 0 termination. If you have to do it, make a `tmp := s.clone()` beforehand, and free the cloned `tmp` string after you have called the C. function with it. The .len field of the result value, will be the same as the buffer.len.

Note: avoid storing or returning that resulting string, and avoid calling the fn with a complex expression (prefer using a temporary variable as an argument).

[[Return to contents]](#Contents)

## reuse_string_as_data
```v
fn reuse_string_as_data(s string) []u8
```

reuse_string_as_data provides a way to treat the memory of a string `s`, as a []u8 buffer. It does not allocate or copy the memory block for the string `s`, but instead creates an array descriptor, that will point to the same memory as the input. The intended use of that function, is to allow calling array methods (defined on []u8), on string values too, without having to copy/allocate by calling .bytes() (that can be too slow and unnecessary in loops).

Note: since there are no allocations, the buffer *will not* contain the terminating `0` byte, that V strings have usually. The .len field of the result value, will be the same as s.len .

Note: avoid storing or returning that resulting byte buffer, and avoid calling the fn with a complex expression (prefer using a temporary variable as an argument).

[[Return to contents]](#Contents)

## str_intp
```v
fn str_intp(data_len int, input_base &StrIntpData) string
```

interpolation function

[[Return to contents]](#Contents)

## str_intp_g32
```v
fn str_intp_g32(in_str string) string
```

[[Return to contents]](#Contents)

## str_intp_g64
```v
fn str_intp_g64(in_str string) string
```

[[Return to contents]](#Contents)

## str_intp_rune
```v
fn str_intp_rune(in_str string) string
```

[[Return to contents]](#Contents)

## str_intp_sq
```v
fn str_intp_sq(in_str string) string
```

[[Return to contents]](#Contents)

## str_intp_sub
```v
fn str_intp_sub(base_str string, in_str string) string
```

replace %% with the in_str

[[Return to contents]](#Contents)

## string_from_wide
```v
fn string_from_wide(_wstr &u16) string
```

string_from_wide creates a V string, encoded in UTF-8, given a windows style string encoded in UTF-16. Note that this function first searches for the string terminator 0 character, and is thus slower, while more convenient compared to string_from_wide2/2 (you have to know the length in advance to use string_from_wide2/2). See also builtin.wchar.to_string/1, for a version that eases working with the platform dependent &wchar_t L"" strings.

[[Return to contents]](#Contents)

## string_from_wide2
```v
fn string_from_wide2(_wstr &u16, len int) string
```

string_from_wide2 creates a V string, encoded in UTF-8, given a windows style string, encoded in UTF-16. It is more efficient, compared to string_from_wide, but it requires you to know the input string length, and to pass it as the second argument. See also builtin.wchar.to_string2/2, for a version that eases working with the platform dependent &wchar_t L"" strings.

[[Return to contents]](#Contents)

## string_to_ansi_not_null_terminated
```v
fn string_to_ansi_not_null_terminated(_str string) []u8
```

string_to_ansi_not_null_terminated returns an ANSI version of the string `_str`.

Note: This is most useful for converting a vstring to an ANSI string under Windows.

Note: The ANSI string return is not null-terminated, then you can use `os.write_file_array` write an ANSI file.

[[Return to contents]](#Contents)

## tos
```v
fn tos(s &u8, len int) string
```

tos creates a V string, given a C style pointer to a 0 terminated block.

Note: the memory block pointed by s is *reused, not copied*! It will panic, when the pointer `s` is 0. See also `tos_clone`.

[[Return to contents]](#Contents)

## tos2
```v
fn tos2(s &u8) string
```

tos2 creates a V string, given a C style pointer to a 0 terminated block.

Note: the memory block pointed by s is *reused, not copied*! It will calculate the length first, thus it is more costly than `tos`. It will panic, when the pointer `s` is 0. It is the same as `tos3`, but for &u8 pointers, avoiding callsite casts. See also `tos_clone`.

[[Return to contents]](#Contents)

## tos3
```v
fn tos3(s &char) string
```

tos3 creates a V string, given a C style pointer to a 0 terminated block.

Note: the memory block pointed by s is *reused, not copied*! It will calculate the length first, so it is more costly than tos. It will panic, when the pointer `s` is 0. It is the same as `tos2`, but for &char pointers, avoiding callsite casts. See also `tos_clone`.

[[Return to contents]](#Contents)

## tos4
```v
fn tos4(s &u8) string
```

tos4 creates a V string, given a C style pointer to a 0 terminated block.

Note: the memory block pointed by s is *reused, not copied*! It will calculate the length first, so it is more costly than tos. It returns '', when given a 0 pointer `s`, it does NOT panic. It is the same as `tos5`, but for &u8 pointers, avoiding callsite casts. See also `tos_clone`.

[[Return to contents]](#Contents)

## tos5
```v
fn tos5(s &char) string
```

tos5 creates a V string, given a C style pointer to a 0 terminated block.

Note: the memory block pointed by s is *reused, not copied*! It will calculate the length first, so it is more costly than tos. It returns '', when given a 0 pointer `s`, it does NOT panic. It is the same as `tos4`, but for &char pointers, avoiding callsite casts. See also `tos_clone`.

[[Return to contents]](#Contents)

## tos_clone
```v
fn tos_clone(const_s &u8) string
```

tos_clone creates a new V string copy of the C style string, pointed by `s`. See also cstring_to_vstring (it is the same as it, the only difference is, that tos_clone expects `&u8`, while cstring_to_vstring expects &char). It will panic, if the pointer `s` is 0.

[[Return to contents]](#Contents)

## unbuffer_stdout
```v
fn unbuffer_stdout()
```

unbuffer_stdout will turn off the default buffering done for stdout. It will affect all consequent print and println calls, effectively making them behave like eprint and eprintln do. It is useful for programs, that want to produce progress bars, without cluttering your code with a flush_stdout() call after every print() call. It is also useful for programs (sensors), that produce small chunks of output, that you want to be able to process immediately. Note 1: if used, *it should be called at the start of your program*, before using print or println(). Note 2: most libc implementations, have logic that use line buffering for stdout, when the output stream is connected to an interactive device, like a terminal, and otherwise fully buffer it, which is good for the output performance for programs that can produce a lot of output (like filters, or cat etc), but bad for latency. Normally, it is usually what you want, so it is the default for V programs too. See https://www.gnu.org/software/libc/manual/html_node/Buffering-Concepts.html . See https://pubs.opengroup.org/onlinepubs/9699919799/functions/V2_chap02.html#tag_15_05 .

[[Return to contents]](#Contents)

## utf32_decode_to_buffer
```v
fn utf32_decode_to_buffer(code u32, mut buf &u8) int
```

[[Return to contents]](#Contents)

## utf32_to_str
```v
fn utf32_to_str(code u32) string
```

Convert utf32 to utf8 utf32 == Codepoint

[[Return to contents]](#Contents)

## utf32_to_str_no_malloc
```v
fn utf32_to_str_no_malloc(code u32, mut buf &u8) string
```

[[Return to contents]](#Contents)

## utf8_char_len
```v
fn utf8_char_len(b u8) int
```

utf8_char_len returns the length in bytes of a UTF-8 encoded codepoint that starts with the byte `b`.

[[Return to contents]](#Contents)

## utf8_str_visible_length
```v
fn utf8_str_visible_length(s string) int
```

Calculate string length for formatting, i.e. number of "characters" This is simplified implementation. if you need specification compliant width, use utf8.east_asian.display_width.

[[Return to contents]](#Contents)

## v_realloc
```v
fn v_realloc(b &u8, n isize) &u8
```

v_realloc resizes the memory block `b` with `n` bytes. The `b byteptr` must be a pointer to an existing memory block previously allocated with `malloc` or `vcalloc`. Please, see also realloc_data, and use it instead if possible.

[[Return to contents]](#Contents)

## vcalloc
```v
fn vcalloc(n isize) &u8
```

vcalloc dynamically allocates a zeroed `n` bytes block of memory on the heap. vcalloc returns a `byteptr` pointing to the memory address of the allocated space. vcalloc checks for negative values given in `n`.

[[Return to contents]](#Contents)

## vcalloc_noscan
```v
fn vcalloc_noscan(n isize) &u8
```

special versions of the above that allocate memory which is not scanned for pointers (but is collected) when the Boehm garbage collection is used

[[Return to contents]](#Contents)

## vcurrent_hash
```v
fn vcurrent_hash() string
```

[[Return to contents]](#Contents)

## vmemcmp
```v
fn vmemcmp(const_s1 voidptr, const_s2 voidptr, n isize) int
```

vmemcmp compares the first n bytes (each interpreted as unsigned char) of the memory areas s1 and s2. It returns an integer less than, equal to, or greater than zero, if the first n bytes of s1 is found, respectively, to be less than, to match, or be greater than the first n bytes of s2. For a nonzero return value, the sign is determined by the sign of the difference between the first pair of bytes (interpreted as unsigned char) that differ in s1 and s2. If n is zero, the return value is zero. Do NOT use vmemcmp to compare security critical data, such as cryptographic secrets, because the required CPU time depends on the number of equal bytes. You should use a function that performs comparisons in constant time for this.

[[Return to contents]](#Contents)

## vmemcpy
```v
fn vmemcpy(dest voidptr, const_src voidptr, n isize) voidptr
```

vmemcpy copies n bytes from memory area src to memory area dest. The memory areas *MUST NOT OVERLAP*.  Use vmemmove, if the memory areas do overlap. vmemcpy returns a pointer to `dest`.

[[Return to contents]](#Contents)

## vmemmove
```v
fn vmemmove(dest voidptr, const_src voidptr, n isize) voidptr
```

vmemmove copies n bytes from memory area `src` to memory area `dest`. The memory areas *MAY* overlap: copying takes place as though the bytes in `src` are first copied into a temporary array that does not overlap `src` or `dest`, and the bytes are then copied from the temporary array to `dest`. vmemmove returns a pointer to `dest`.

[[Return to contents]](#Contents)

## vmemset
```v
fn vmemset(s voidptr, c int, n isize) voidptr
```

vmemset fills the first `n` bytes of the memory area pointed to by `s`, with the constant byte `c`. It returns a pointer to the memory area `s`.

[[Return to contents]](#Contents)

## vstrlen
```v
fn vstrlen(s &u8) int
```

vstrlen returns the V length of the C string `s` (0 terminator is not counted). The C string is expected to be a &u8 pointer.

[[Return to contents]](#Contents)

## vstrlen_char
```v
fn vstrlen_char(s &char) int
```

vstrlen_char returns the V length of the C string `s` (0 terminator is not counted). The C string is expected to be a &char pointer.

[[Return to contents]](#Contents)

## wide_to_ansi
```v
fn wide_to_ansi(_wstr &u16) []u8
```

wide_to_ansi create an ANSI string, given a windows style string, encoded in UTF-16. It use CP_ACP, which is ANSI code page identifier, as dest encoding.

Note: It return a vstring(encoded in UTF-8) []u8 under Linux.

[[Return to contents]](#Contents)

## IError
```v
interface IError {
	msg() string
	code() int
}
```

IError holds information about an error instance.

[[Return to contents]](#Contents)

## free
```v
fn (ie &IError) free()
```

[[Return to contents]](#Contents)

## str
```v
fn (err IError) str() string
```

str returns the message of IError.

[[Return to contents]](#Contents)

## C.intptr_t
```v
type C.intptr_t = voidptr
```

[[Return to contents]](#Contents)

## FnExitCb
```v
type FnExitCb = fn ()
```

[[Return to contents]](#Contents)

## FnGC_WarnCB
```v
type FnGC_WarnCB = fn (msg &char, arg usize)
```

FnGC_WarnCB is the type of the callback, that you have to define, if you want to redirect GC warnings and handle them.

Note: GC warnings are silenced by default. Use gc_set_warn_proc/1 to set your own handler for them.

[[Return to contents]](#Contents)

## MessageError
## str
```v
fn (err MessageError) str() string
```

str returns both the .msg and .code of MessageError, when .code is != 0 .

[[Return to contents]](#Contents)

## msg
```v
fn (err MessageError) msg() string
```

msg returns only the message of MessageError.

[[Return to contents]](#Contents)

## code
```v
fn (err MessageError) code() int
```

code returns only the code of MessageError.

[[Return to contents]](#Contents)

## free
```v
fn (err &MessageError) free()
```

[[Return to contents]](#Contents)

## []rune
## string
```v
fn (ra []rune) string() string
```

string converts a rune array to a string.

[[Return to contents]](#Contents)

## []string
## free
```v
fn (mut a []string) free()
```

[[Return to contents]](#Contents)

## join
```v
fn (a []string) join(sep string) string
```

join joins a string array into a string using `sep` separator.

Example
```v

assert ['Hello','V'].join(' ') == 'Hello V'

```

[[Return to contents]](#Contents)

## join_lines
```v
fn (s []string) join_lines() string
```

join_lines joins a string array into a string using a `\n` newline delimiter.

[[Return to contents]](#Contents)

## sort_by_len
```v
fn (mut s []string) sort_by_len()
```

sort_by_len sorts the string array by each string's `.len` length.

[[Return to contents]](#Contents)

## sort_ignore_case
```v
fn (mut s []string) sort_ignore_case()
```

sort_ignore_case sorts the string array using case insensitive comparing.

[[Return to contents]](#Contents)

## str
```v
fn (a []string) str() string
```

str returns a string representation of an array of strings.

Example
```v

assert ['a', 'b', 'c'].str() == "['a', 'b', 'c']"

```

[[Return to contents]](#Contents)

## []u8
## byterune
```v
fn (b []u8) byterune() !rune
```

byterune attempts to decode a sequence of bytes, from utf8 to utf32. It return the result as a rune. It will produce an error, if there are more than four bytes in the array.

[[Return to contents]](#Contents)

## bytestr
```v
fn (b []u8) bytestr() string
```

bytestr produces a string from *all* the bytes in the array.

Note: the returned string will have .len equal to the array.len, even when some of the array bytes were `0`. If you want to get a V string, that contains only the bytes till the first `0` byte, use `tos_clone(&u8(array.data))` instead.

[[Return to contents]](#Contents)

## hex
```v
fn (b []u8) hex() string
```

hex returns a string with the hexadecimal representation of the byte elements of the array `b`.

[[Return to contents]](#Contents)

## utf8_to_utf32
```v
fn (_bytes []u8) utf8_to_utf32() !rune
```

convert array of utf8 bytes to single utf32 value will error if more than 4 bytes are submitted

[[Return to contents]](#Contents)

## bool
## str
```v
fn (b bool) str() string
```

str returns the value of the `bool` as a `string`.

Example
```v

assert (2 > 1).str() == 'true'

```

[[Return to contents]](#Contents)

## byte
```v
type byte = u8
```

[[Return to contents]](#Contents)

## byteptr
## str
```v
fn (nn byteptr) str() string
```

hex returns the value of the `byteptr` as a hexadecimal `string`. Note that the output is ***not*** zero padded. pub fn (nn byteptr) str() string {

[[Return to contents]](#Contents)

## vbytes
```v
fn (data byteptr) vbytes(len int) []u8
```

byteptr.vbytes() - makes a V []u8 structure from a C style memory buffer. Note: the data is reused, NOT copied!

[[Return to contents]](#Contents)

## vstring
```v
fn (bp byteptr) vstring() string
```

vstring converts a C style string to a V string. Note: the string data is reused, NOT copied. strings returned from this function will be normal V strings beside that (i.e. they would be freed by V's -autofree mechanism, when they are no longer used).

[[Return to contents]](#Contents)

## vstring_literal
```v
fn (bp byteptr) vstring_literal() string
```

vstring_literal converts a C style string to a V string.

Note: the string data is reused, NOT copied. NB2: unlike vstring, vstring_literal will mark the string as a literal, so it will not be freed by autofree. This is suitable for readonly strings, C string literals etc, that can be read by the V program, but that should not be managed by it, for example `os.args` is implemented using it.

[[Return to contents]](#Contents)

## vstring_literal_with_len
```v
fn (bp byteptr) vstring_literal_with_len(len int) string
```

vstring_with_len converts a C style string to a V string.

Note: the string data is reused, NOT copied.

[[Return to contents]](#Contents)

## vstring_with_len
```v
fn (bp byteptr) vstring_with_len(len int) string
```

vstring_with_len converts a C style string to a V string.

Note: the string data is reused, NOT copied.

[[Return to contents]](#Contents)

## chan
## close
```v
fn (ch chan) close()
```

close closes the channel for further push transactions. closed channels cannot be pushed to, however they can be popped from as long as there is still objects available in the channel buffer.

[[Return to contents]](#Contents)

## try_pop
```v
fn (ch chan) try_pop(obj voidptr) ChanState
```

try_pop returns `ChanState.success` if an object is popped from the channel. try_pop effectively pops from the channel without waiting for objects to become available. Both the test and pop transaction is done atomically.

[[Return to contents]](#Contents)

## try_push
```v
fn (ch chan) try_push(obj voidptr) ChanState
```

try_push returns `ChanState.success` if the object is pushed to the channel. try_push effectively both push and test if the transaction `ch <- a` succeeded. Both the test and push transaction is done atomically.

[[Return to contents]](#Contents)

## char
## str
```v
fn (cptr &char) str() string
```

str returns a string with the address stored in the pointer cptr.

[[Return to contents]](#Contents)

## vstring
```v
fn (cp &char) vstring() string
```

vstring converts a C style string to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*! Strings returned from this function will be normal V strings beside that, (i.e. they would be freed by V's -autofree mechanism, when they are no longer used).

Note: instead of `&u8(a.data).vstring()`, use `tos_clone(&u8(a.data))`. See also `tos_clone`.

[[Return to contents]](#Contents)

## vstring_literal
```v
fn (cp &char) vstring_literal() string
```

vstring_literal converts a C style string char* pointer to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*! See also `byteptr.vstring_literal` for more details. See also `tos_clone`.

[[Return to contents]](#Contents)

## vstring_literal_with_len
```v
fn (cp &char) vstring_literal_with_len(len int) string
```

vstring_literal_with_len converts a C style string char* pointer, to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*! This method has lower overhead compared to .vstring_literal(), since it does not need to calculate the length of the 0 terminated string. See also `tos_clone`.

[[Return to contents]](#Contents)

## vstring_with_len
```v
fn (cp &char) vstring_with_len(len int) string
```

vstring_with_len converts a C style 0 terminated string to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*! This method has lower overhead compared to .vstring(), since it does not calculate the length of the 0 terminated string. See also `tos_clone`.

[[Return to contents]](#Contents)

## charptr
## str
```v
fn (nn charptr) str() string
```

[[Return to contents]](#Contents)

## vstring
```v
fn (cp charptr) vstring() string
```

vstring converts C char* to V string.

Note: the string data is reused, NOT copied.

[[Return to contents]](#Contents)

## vstring_literal
```v
fn (cp charptr) vstring_literal() string
```

vstring_literal converts C char* to V string. See also vstring_literal defined on byteptr for more details.

Note: the string data is reused, NOT copied.

[[Return to contents]](#Contents)

## vstring_literal_with_len
```v
fn (cp charptr) vstring_literal_with_len(len int) string
```

vstring_literal_with_len converts C char* to V string. See also vstring_literal_with_len defined on byteptr.

Note: the string data is reused, NOT copied.

[[Return to contents]](#Contents)

## vstring_with_len
```v
fn (cp charptr) vstring_with_len(len int) string
```

vstring_with_len converts C char* to V string.

Note: the string data is reused, NOT copied.

[[Return to contents]](#Contents)

## f32
## str
```v
fn (x f32) str() string
```

str returns a `f32` as `string` in suitable notation.

[[Return to contents]](#Contents)

## strg
```v
fn (x f32) strg() string
```

strg return a `f32` as `string` in "g" printf format

[[Return to contents]](#Contents)

## strsci
```v
fn (x f32) strsci(digit_num int) string
```

strsci returns the `f32` as a `string` in scientific notation with `digit_num` decimals displayed, max 8 digits.

Example
```v

assert f32(1.234).strsci(3) == '1.234e+00'

```

[[Return to contents]](#Contents)

## strlong
```v
fn (x f32) strlong() string
```

strlong returns a decimal notation of the `f32` as a `string`.

[[Return to contents]](#Contents)

## eq_epsilon
```v
fn (a f32) eq_epsilon(b f32) bool
```

eq_epsilon returns true if the `f32` is equal to input `b`. using an epsilon of typically 1E-5 or higher (backend/compiler dependent).

Example
```v

assert f32(2.0).eq_epsilon(2.0)

```

[[Return to contents]](#Contents)

## f64
## str
```v
fn (x f64) str() string
```

[[Return to contents]](#Contents)

## strg
```v
fn (x f64) strg() string
```

strg return a `f64` as `string` in "g" printf format

[[Return to contents]](#Contents)

## strsci
```v
fn (x f64) strsci(digit_num int) string
```

strsci returns the `f64` as a `string` in scientific notation with `digit_num` decimals displayed, max 17 digits.

Example
```v

assert f64(1.234).strsci(3) == '1.234e+00'

```

[[Return to contents]](#Contents)

## strlong
```v
fn (x f64) strlong() string
```

strlong returns a decimal notation of the `f64` as a `string`.

Example
```v

assert f64(1.23456).strlong() == '1.23456'

```

[[Return to contents]](#Contents)

## eq_epsilon
```v
fn (a f64) eq_epsilon(b f64) bool
```

eq_epsilon returns true if the `f64` is equal to input `b`. using an epsilon of typically 1E-9 or higher (backend/compiler dependent).

Example
```v

assert f64(2.0).eq_epsilon(2.0)

```

[[Return to contents]](#Contents)

## float literal
## str
```v
fn (d float_literal) str() string
```

str returns the value of the `float_literal` as a `string`.

[[Return to contents]](#Contents)

## i16
## str
```v
fn (n i16) str() string
```

str returns the value of the `i16` as a `string`.

Example
```v

assert i16(-20).str() == '-20'

```

[[Return to contents]](#Contents)

## hex
```v
fn (nn i16) hex() string
```

hex returns the value of the `i16` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

Examples
```v

assert i16(2).hex() == '2'

assert i16(200).hex() == 'c8'

```

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn i16) hex_full() string
```

[[Return to contents]](#Contents)

## i32
## str
```v
fn (n i32) str() string
```

[[Return to contents]](#Contents)

## i64
## str
```v
fn (nn i64) str() string
```

str returns the value of the `i64` as a `string`.

Example
```v

assert i64(-200000).str() == '-200000'

```

[[Return to contents]](#Contents)

## hex
```v
fn (nn i64) hex() string
```

hex returns the value of the `i64` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

Examples
```v

assert i64(2).hex() == '2'

assert i64(-200).hex() == 'ffffffffffffff38'

assert i64(2021).hex() == '7e5'

```

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn i64) hex_full() string
```

[[Return to contents]](#Contents)

## i8
## str
```v
fn (n i8) str() string
```

str returns the value of the `i8` as a `string`.

Example
```v

assert i8(-2).str() == '-2'

```

[[Return to contents]](#Contents)

## hex
```v
fn (nn i8) hex() string
```

hex returns the value of the `i8` as a hexadecimal `string`. Note that the output is zero padded for values below 16.

Examples
```v

assert i8(8).hex() == '08'

assert i8(10).hex() == '0a'

assert i8(15).hex() == '0f'

```

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn i8) hex_full() string
```

[[Return to contents]](#Contents)

## int
## hex_full
```v
fn (nn int) hex_full() string
```

[[Return to contents]](#Contents)

## str
```v
fn (n int) str() string
```

str returns the value of the `int` as a `string`.

Example
```v

assert int(-2020).str() == '-2020'

```

[[Return to contents]](#Contents)

## hex
```v
fn (nn int) hex() string
```

hex returns the value of the `int` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

Examples
```v

assert int(2).hex() == '2'

assert int(200).hex() == 'c8'

```

[[Return to contents]](#Contents)

## hex2
```v
fn (n int) hex2() string
```

hex2 returns the value of the `int` as a `0x`-prefixed hexadecimal `string`. Note that the output after `0x` is ***not*** zero padded.

Examples
```v

assert int(8).hex2() == '0x8'

assert int(15).hex2() == '0xf'

assert int(18).hex2() == '0x12'

```

[[Return to contents]](#Contents)

## int literal
## str
```v
fn (n int_literal) str() string
```

str returns the value of the `int_literal` as a `string`.

[[Return to contents]](#Contents)

## hex
```v
fn (nn int_literal) hex() string
```

hex returns the value of the `int_literal` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn int_literal) hex_full() string
```

[[Return to contents]](#Contents)

## isize
## str
```v
fn (x isize) str() string
```

str returns the string equivalent of x.

[[Return to contents]](#Contents)

## none
## str
```v
fn (_ none) str() string
```

str for none, returns 'none'

[[Return to contents]](#Contents)

## rune
## str
```v
fn (c rune) str() string
```

str converts a rune to string.

[[Return to contents]](#Contents)

## repeat
```v
fn (c rune) repeat(count int) string
```

repeat returns a new string with `count` number of copies of the rune it was called on.

[[Return to contents]](#Contents)

## bytes
```v
fn (c rune) bytes() []u8
```

bytes converts a rune to an array of bytes.

[[Return to contents]](#Contents)

## length_in_bytes
```v
fn (c rune) length_in_bytes() int
```

length_in_bytes returns the number of bytes needed to store the code point. Returns -1 if the data is not a valid code point.

[[Return to contents]](#Contents)

## to_upper
```v
fn (c rune) to_upper() rune
```

`to_upper` convert to uppercase mode.

[[Return to contents]](#Contents)

## to_lower
```v
fn (c rune) to_lower() rune
```

`to_lower` convert to lowercase mode.

[[Return to contents]](#Contents)

## to_title
```v
fn (c rune) to_title() rune
```

`to_title` convert to title mode.

[[Return to contents]](#Contents)

## u16
## str
```v
fn (n u16) str() string
```

str returns the value of the `u16` as a `string`.

Example
```v

assert u16(20).str() == '20'

```

[[Return to contents]](#Contents)

## hex
```v
fn (nn u16) hex() string
```

hex returns the value of the `u16` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

Examples
```v

assert u16(2).hex() == '2'

assert u16(200).hex() == 'c8'

```

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn u16) hex_full() string
```

[[Return to contents]](#Contents)

## u32
## str
```v
fn (nn u32) str() string
```

str returns the value of the `u32` as a `string`.

Example
```v

assert u32(20000).str() == '20000'

```

[[Return to contents]](#Contents)

## hex
```v
fn (nn u32) hex() string
```

hex returns the value of the `u32` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

Examples
```v

assert u32(2).hex() == '2'

assert u32(200).hex() == 'c8'

```

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn u32) hex_full() string
```

[[Return to contents]](#Contents)

## u64
## str
```v
fn (nn u64) str() string
```

str returns the value of the `u64` as a `string`.

Example
```v

assert u64(2000000).str() == '2000000'

```

[[Return to contents]](#Contents)

## hex
```v
fn (nn u64) hex() string
```

hex returns the value of the `u64` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

Examples
```v

assert u64(2).hex() == '2'

assert u64(2000).hex() == '7d0'

```

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn u64) hex_full() string
```

hex_full returns the value of the `u64` as a *full* 16-digit hexadecimal `string`.

Examples
```v

assert u64(2).hex_full() == '0000000000000002'

assert u64(255).hex_full() == '00000000000000ff'

```

[[Return to contents]](#Contents)

## u8
## ascii_str
```v
fn (b u8) ascii_str() string
```

ascii_str returns the contents of `byte` as a zero terminated ASCII `string` character.

Example
```v

assert u8(97).ascii_str() == 'a'

```

[[Return to contents]](#Contents)

## free
```v
fn (data &u8) free()
```

free frees the memory allocated

[[Return to contents]](#Contents)

## hex
```v
fn (nn u8) hex() string
```

hex returns the value of the `byte` as a hexadecimal `string`. Note that the output is zero padded for values below 16.

Examples
```v

assert u8(2).hex() == '02'

assert u8(15).hex() == '0f'

assert u8(255).hex() == 'ff'

```

[[Return to contents]](#Contents)

## hex_full
```v
fn (nn u8) hex_full() string
```

[[Return to contents]](#Contents)

## is_alnum
```v
fn (c u8) is_alnum() bool
```

is_alnum returns `true` if the byte is in range a-z, A-Z, 0-9 and `false` otherwise.

Example
```v

assert u8(`V`).is_alnum() == true

```

[[Return to contents]](#Contents)

## is_bin_digit
```v
fn (c u8) is_bin_digit() bool
```

is_bin_digit returns `true` if the byte is a binary digit (0 or 1) and `false` otherwise.

Example
```v

assert u8(`0`).is_bin_digit() == true

```

[[Return to contents]](#Contents)

## is_capital
```v
fn (c u8) is_capital() bool
```

is_capital returns `true`, if the byte is a Latin capital letter.

Examples
```v

assert u8(`H`).is_capital() == true

assert u8(`h`).is_capital() == false

```

[[Return to contents]](#Contents)

## is_digit
```v
fn (c u8) is_digit() bool
```

is_digit returns `true` if the byte is in range 0-9 and `false` otherwise.

Example
```v

assert u8(`9`).is_digit() == true

```

[[Return to contents]](#Contents)

## is_hex_digit
```v
fn (c u8) is_hex_digit() bool
```

is_hex_digit returns `true` if the byte is either in range 0-9, a-f or A-F and `false` otherwise.

Example
```v

assert u8(`F`).is_hex_digit() == true

```

[[Return to contents]](#Contents)

## is_letter
```v
fn (c u8) is_letter() bool
```

is_letter returns `true` if the byte is in range a-z or A-Z and `false` otherwise.

Example
```v

assert u8(`V`).is_letter() == true

```

[[Return to contents]](#Contents)

## is_oct_digit
```v
fn (c u8) is_oct_digit() bool
```

is_oct_digit returns `true` if the byte is in range 0-7 and `false` otherwise.

Example
```v

assert u8(`7`).is_oct_digit() == true

```

[[Return to contents]](#Contents)

## is_space
```v
fn (c u8) is_space() bool
```

is_space returns `true` if the byte is a white space character. The following list is considered white space characters: ` `, `\t`, `\n`, `\v`, `\f`, `\r`, 0x85, 0xa0

Example
```v

assert u8(` `).is_space() == true

```

[[Return to contents]](#Contents)

## repeat
```v
fn (b u8) repeat(count int) string
```

repeat returns a new string with `count` number of copies of the byte it was called on.

[[Return to contents]](#Contents)

## str
```v
fn (b u8) str() string
```

str returns the contents of `byte` as a zero terminated `string`. See also: [`byte.ascii_str`](#byte.ascii_str)

Example
```v

assert u8(111).str() == '111'

```

[[Return to contents]](#Contents)

## str_escaped
```v
fn (b u8) str_escaped() string
```

str_escaped returns the contents of `byte` as an escaped `string`.

Example
```v

assert u8(0).str_escaped() == r'`\0`'

```

[[Return to contents]](#Contents)

## vbytes
```v
fn (data &u8) vbytes(len int) []u8
```

vbytes on `&u8` makes a V []u8 structure from a C style memory buffer.

Note: the data is reused, NOT copied!

[[Return to contents]](#Contents)

## vstring
```v
fn (bp &u8) vstring() string
```

vstring converts a C style string to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*!

Note: instead of `&u8(arr.data).vstring()`, do use `tos_clone(&u8(arr.data))`. Strings returned from this function will be normal V strings beside that, (i.e. they would be freed by V's -autofree mechanism, when they are no longer used). See also `tos_clone`.

[[Return to contents]](#Contents)

## vstring_literal
```v
fn (bp &u8) vstring_literal() string
```

vstring_literal converts a C style string to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*! NB2: unlike vstring, vstring_literal will mark the string as a literal, so it will not be freed by -autofree. This is suitable for readonly strings, C string literals etc, that can be read by the V program, but that should not be managed/freed by it, for example `os.args` is implemented using it. See also `tos_clone`.

[[Return to contents]](#Contents)

## vstring_literal_with_len
```v
fn (bp &u8) vstring_literal_with_len(len int) string
```

vstring_with_len converts a C style string to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*! This method has lower overhead compared to .vstring_literal(), since it does not need to calculate the length of the 0 terminated string. See also `tos_clone`.

[[Return to contents]](#Contents)

## vstring_with_len
```v
fn (bp &u8) vstring_with_len(len int) string
```

vstring_with_len converts a C style 0 terminated string to a V string.

Note: the memory block pointed by `bp` is *reused, not copied*! This method has lower overhead compared to .vstring(), since it does not need to calculate the length of the 0 terminated string. See also `tos_clone`.

[[Return to contents]](#Contents)

## usize
## str
```v
fn (x usize) str() string
```

str returns the string equivalent of x.

[[Return to contents]](#Contents)

## voidptr
## hex_full
```v
fn (nn voidptr) hex_full() string
```

[[Return to contents]](#Contents)

## str
```v
fn (nn voidptr) str() string
```

hex returns the value of the `voidptr` as a hexadecimal `string`. Note that the output is ***not*** zero padded.

[[Return to contents]](#Contents)

## vbytes
```v
fn (data voidptr) vbytes(len int) []u8
```

vbytes on`voidptr` makes a V []u8 structure from a C style memory buffer.

Note: the data is reused, NOT copied!

[[Return to contents]](#Contents)

## ArrayFlags
```v
enum ArrayFlags {
	noslices // when <<, `.noslices` will free the old data block immediately (you have to be sure, that there are *no slices* to that specific array). TODO: integrate with reference counting/compiler support for the static cases.
	noshrink // when `.noslices` and `.noshrink` are *both set*, .delete(x) will NOT allocate new memory and free the old. It will just move the elements in place, and adjust .len.
	nogrow   // the array will never be allowed to grow past `.cap`. set `.nogrow` and `.noshrink` for a truly fixed heap array
	nofree   // `.data` will never be freed
}
```

[[Return to contents]](#Contents)

## AttributeKind
```v
enum AttributeKind {
	plain           // [name]
	string          // ['name']
	number          // [123]
	bool            // [true] || [false]
	comptime_define // [if name]	
}
```

[[Return to contents]](#Contents)

## ChanState
```v
enum ChanState {
	success
	not_ready // push()/pop() would have to wait, but no_block was requested
	closed
}
```

ChanState describes the result of an attempted channel transaction.

[[Return to contents]](#Contents)

## StrIntpType
```v
enum StrIntpType {
	si_no_str = 0 // no parameter to print only fix string
	si_c
	si_u8
	si_i8
	si_u16
	si_i16
	si_u32
	si_i32
	si_u64
	si_i64
	si_e32
	si_e64
	si_f32
	si_f64
	si_g32
	si_g64
	si_s
	si_p
	si_r
	si_vp
}
```



[[Return to contents]](#Contents)

## str
```v
fn (x StrIntpType) str() string
```

[[Return to contents]](#Contents)

## C.DIR
```v
struct C.DIR {
}
```

[[Return to contents]](#Contents)

## C.FILE
```v
struct C.FILE {}
```

[[Return to contents]](#Contents)

## C.GC_stack_base
```v
struct C.GC_stack_base {
	mem_base voidptr
	// reg_base voidptr
}
```

[[Return to contents]](#Contents)

## C.IError
```v
struct C.IError {
	_object voidptr
}
```

[[Return to contents]](#Contents)

## C.SRWLOCK
```v
struct C.SRWLOCK {}
```

[[Return to contents]](#Contents)

## C.SYSTEM_INFO
```v
struct C.SYSTEM_INFO {
	dwNumberOfProcessors u32
	dwPageSize           u32
}
```

C.SYSTEM_INFO contains information about the current computer system. This includes the architecture and type of the processor, the number of processors in the system, the page size, and other such information.

[[Return to contents]](#Contents)

## EnumData
```v
struct EnumData {
pub:
	name  string
	value i64
	attrs []string
}
```

[[Return to contents]](#Contents)

## Error
```v
struct Error {}
```

Error is the empty default implementation of `IError`.

[[Return to contents]](#Contents)

## msg
```v
fn (err Error) msg() string
```

[[Return to contents]](#Contents)

## code
```v
fn (err Error) code() int
```

[[Return to contents]](#Contents)

## FieldData
```v
struct FieldData {
pub:
	name          string // the name of the field f
	typ           int    // the internal TypeID of the field f,
	unaliased_typ int    // if f's type was an alias of int, this will be TypeID(int)

	attrs  []string // the attributes of the field f
	is_pub bool     // f is in a `pub:` section
	is_mut bool     // f is in a `mut:` section

	is_shared bool // `f shared Abc`
	is_atomic bool // `f atomic int` , TODO
	is_option bool // `f ?string` , TODO

	is_array  bool // `f []string` , TODO
	is_map    bool // `f map[string]int` , TODO
	is_chan   bool // `f chan int` , TODO
	is_enum   bool // `f Enum` where Enum is an enum
	is_struct bool // `f Abc` where Abc is a struct , TODO
	is_alias  bool // `f MyInt` where `type MyInt = int`, TODO

	indirections u8 // 0 for `f int`, 1 for `f &int`, 2 for `f &&int` , TODO
}
```

FieldData holds information about a field. Fields reside on structs.

[[Return to contents]](#Contents)

## FunctionData
```v
struct FunctionData {
pub:
	name        string
	attrs       []string
	args        []MethodParam
	return_type int
	typ         int
}
```

FunctionData holds information about a parsed function.

[[Return to contents]](#Contents)

## GCHeapUsage
```v
struct GCHeapUsage {
pub:
	heap_size      usize
	free_bytes     usize
	total_bytes    usize
	unmapped_bytes usize
	bytes_since_gc usize
}
```

GCHeapUsage contains stats about the current heap usage of your program.

[[Return to contents]](#Contents)

## MethodParam
```v
struct MethodParam {
pub:
	typ  int
	name string
}
```

MethodParam holds type information for function and/or method arguments.

[[Return to contents]](#Contents)

## RunesIterator
```v
struct RunesIterator {
mut:
	s string
	i int
}
```

[[Return to contents]](#Contents)

## next
```v
fn (mut ri RunesIterator) next() ?rune
```

next is the method that will be called for each iteration in `for r in s.runes_iterator() {` .

[[Return to contents]](#Contents)

## SortedMap
```v
struct SortedMap {
	value_bytes int
mut:
	root &mapnode
pub mut:
	len int
}
```

[[Return to contents]](#Contents)

## delete
```v
fn (mut m SortedMap) delete(key string)
```

[[Return to contents]](#Contents)

## keys
```v
fn (m &SortedMap) keys() []string
```

[[Return to contents]](#Contents)

## free
```v
fn (mut m SortedMap) free()
```

[[Return to contents]](#Contents)

## print
```v
fn (m SortedMap) print()
```

[[Return to contents]](#Contents)

## StrIntpCgenData
```v
struct StrIntpCgenData {
pub:
	str string
	fmt string
	d   string
}
```

storing struct used by cgen

[[Return to contents]](#Contents)

## StrIntpData
```v
struct StrIntpData {
pub:
	str string
	// fmt     u64  // expanded version for future use, 64 bit
	fmt u32
	d   StrIntpMem
}
```



Note: LOW LEVEL structstoring struct passed to V in the C code

[[Return to contents]](#Contents)

## StrIntpMem
```v
union StrIntpMem {
pub mut:
	d_c   u32
	d_u8  u8
	d_i8  i8
	d_u16 u16
	d_i16 i16
	d_u32 u32
	d_i32 int
	d_u64 u64
	d_i64 i64
	d_f32 f32
	d_f64 f64
	d_s   string
	d_r   string
	d_p   voidptr
	d_vp  voidptr
}
```

Union data used by StrIntpData

[[Return to contents]](#Contents)

## VAssertMetaInfo
```v
struct VAssertMetaInfo {
pub:
	fpath   string // the source file path of the assertion
	line_nr int    // the line number of the assertion
	fn_name string // the function name in which the assertion is
	src     string // the actual source line of the assertion
	op      string // the operation of the assertion, i.e. '==', '<', 'call', etc ...
	llabel  string // the left side of the infix expressions as source
	rlabel  string // the right side of the infix expressions as source
	lvalue  string // the stringified *actual value* of the left side of a failed assertion
	rvalue  string // the stringified *actual value* of the right side of a failed assertion
	message string // the value of the `message` from `assert cond, message`
	has_msg bool   // false for assertions like `assert cond`, true for `assert cond, 'oh no'`
}
```

VAssertMetaInfo is used during assertions. An instance of it is filled in by compile time generated code, when an assertion fails.

[[Return to contents]](#Contents)

## free
```v
fn (ami &VAssertMetaInfo) free()
```

free frees the memory occupied by the assertion meta data. It is called automatically by the code, that V's test framework generates, after all other callbacks have been called.

[[Return to contents]](#Contents)

## VAttribute
```v
struct VAttribute {
pub:
	name    string
	has_arg bool
	arg     string
	kind    AttributeKind
}
```

[[Return to contents]](#Contents)

## VContext
```v
struct VContext {
	allocator int
}
```

[[Return to contents]](#Contents)

## VariantData
```v
struct VariantData {
pub:
	typ int
}
```

[[Return to contents]](#Contents)

## WrapConfig
```v
struct WrapConfig {
pub:
	width int    = 80
	end   string = '\n'
}
```

[[Return to contents]](#Contents)

## array
```v
struct array {
pub mut:
	data   voidptr
	offset int // in bytes (should be `usize`), to avoid copying data while making slices, unless it starts changing
	len    int // length of the array in elements.
	cap    int // capacity of the array in elements.
	flags  ArrayFlags
pub:
	element_size int // size in bytes of one element in the array.
}
```

array is a struct, used for denoting all array types in V. `.data` is a void pointer to the backing heap memory block, which avoids using generics and thus without generating extra code for every type.

[[Return to contents]](#Contents)

## ensure_cap
```v
fn (mut a array) ensure_cap(required int)
```

ensure_cap increases the `cap` of an array to the required value, if needed. It does so by copying the data to a new memory location (creating a clone), unless `a.cap` is already large enough.

[[Return to contents]](#Contents)

## repeat
```v
fn (a array) repeat(count int) array
```

repeat returns a new array with the given array elements repeated given times. `cgen` will replace this with an appropriate call to `repeat_to_depth()`

This is a dummy placeholder that will be overridden by `cgen` with an appropriate call to `repeat_to_depth()`. However the `checker` needs it here.

[[Return to contents]](#Contents)

## repeat_to_depth
```v
fn (a array) repeat_to_depth(count int, depth int) array
```

repeat_to_depth is an unsafe version of `repeat()` that handles multi-dimensional arrays.

It is `unsafe` to call directly because `depth` is not checked

[[Return to contents]](#Contents)

## insert
```v
fn (mut a array) insert(i int, val voidptr)
```

insert inserts a value in the array at index `i` and increases the index of subsequent elements by 1.

This function is type-aware and can insert items of the same or lower dimensionality as the original array. That is, if the original array is `[]int`, then the insert `val` may be `int` or `[]int`. If the original array is `[][]int`, then `val` may be `[]int` or `[][]int`. Consider the examples.



Example
```v

mut a := [1, 2, 4]
a.insert(2, 3)          // a now is [1, 2, 3, 4]
mut b := [3, 4]
b.insert(0, [1, 2])     // b now is [1, 2, 3, 4]
mut c := [[3, 4]]
c.insert(0, [1, 2])     // c now is [[1, 2], [3, 4]]

```

[[Return to contents]](#Contents)

## prepend
```v
fn (mut a array) prepend(val voidptr)
```

prepend prepends one or more elements to an array. It is shorthand for `.insert(0, val)`

[[Return to contents]](#Contents)

## delete
```v
fn (mut a array) delete(i int)
```

delete deletes array element at index `i`. This is exactly the same as calling `.delete_many(i, 1)`.

Note: This function does NOT operate in-place. Internally, it creates a copy of the array, skipping over the element at `i`, and then points the original variable to the new memory location.



Example
```v

mut a := ['0', '1', '2', '3', '4', '5']
a.delete(1) // a is now ['0', '2', '3', '4', '5']

```

[[Return to contents]](#Contents)

## delete_many
```v
fn (mut a array) delete_many(i int, size int)
```

delete_many deletes `size` elements beginning with index `i`

Note: This function does NOT operate in-place. Internally, it creates a copy of the array, skipping over `size` elements starting at `i`, and then points the original variable to the new memory location.



Example
```v

mut a := [1, 2, 3, 4, 5, 6, 7, 8, 9]
b := unsafe { a[..9] } // creates a `slice` of `a`, not a clone
a.delete_many(4, 3) // replaces `a` with a modified clone
dump(a) // a: [1, 2, 3, 4, 8, 9] // `a` is now different
dump(b) // b: [1, 2, 3, 4, 5, 6, 7, 8, 9] // `b` is still the same

```

[[Return to contents]](#Contents)

## clear
```v
fn (mut a array) clear()
```

clear clears the array without deallocating the allocated data. It does it by setting the array length to `0`

Example
```v

mut a := [1,2]; a.clear(); assert a.len == 0

```

[[Return to contents]](#Contents)

## reset
```v
fn (mut a array) reset()
```

reset quickly sets the bytes of all elements of the array to 0. Useful mainly for numeric arrays. Note, that calling reset() is not safe, when your array contains more complex elements, like structs, maps, pointers etc, since setting them to 0, can later lead to hard to find bugs.

[[Return to contents]](#Contents)

## trim
```v
fn (mut a array) trim(index int)
```

trim trims the array length to `index` without modifying the allocated data. If `index` is greater than `len` nothing will be changed.

Example
```v

mut a := [1,2,3,4]; a.trim(3); assert a.len == 3

```

[[Return to contents]](#Contents)

## drop
```v
fn (mut a array) drop(num int)
```

drop advances the array past the first `num` elements whilst preserving spare capacity. If `num` is greater than `len` the array will be emptied.

Example
```v

mut a := [1,2]
a << 3
a.drop(2)
assert a == [3]
assert a.cap > a.len

```

[[Return to contents]](#Contents)

## first
```v
fn (a array) first() voidptr
```

first returns the first element of the `array`. If the `array` is empty, this will panic. However, `a[0]` returns an error object so it can be handled with an `or` block.

[[Return to contents]](#Contents)

## last
```v
fn (a array) last() voidptr
```

last returns the last element of the `array`. If the `array` is empty, this will panic.

[[Return to contents]](#Contents)

## pop_left
```v
fn (mut a array) pop_left() voidptr
```

pop_left returns the first element of the array and removes it by advancing the data pointer. If the `array` is empty, this will panic.

Note: This function:- Reduces both length and capacity by 1
- Advances the underlying data pointer by one element
- Leaves subsequent elements in-place (no memory copying)
Sliced views will retain access to the original first element position, which is now detached from the array's active memory range.



Example
```v

mut a := [1, 2, 3, 4, 5]
b := unsafe { a[..5] } // full slice view
first := a.pop_left()

// Array now starts from second element
dump(a) // a: [2, 3, 4, 5]
assert a.len == 4
assert a.cap == 4

// Slice retains original memory layout
dump(b) // b: [1, 2, 3, 4, 5]
assert b.len == 5

assert first == 1

// Modifications affect both array and slice views
a[0] = 99
assert b[1] == 99  // changed in both

```

[[Return to contents]](#Contents)

## pop
```v
fn (mut a array) pop() voidptr
```

pop returns the last element of the array, and removes it. If the `array` is empty, this will panic.

Note: this function reduces the length of the given array, but arrays sliced from this one will not change. They still retain their "view" of the underlying memory.



Example
```v

mut a := [1, 2, 3, 4, 5, 6, 7, 8, 9]
b := unsafe{ a[..9] } // creates a "view" (also called a slice) into the same memory
c := a.pop()
assert c == 9
a[1] = 5
dump(a) // a: [1, 5, 3, 4, 5, 6, 7, 8]
dump(b) // b: [1, 5, 3, 4, 5, 6, 7, 8, 9]
assert a.len == 8
assert b.len == 9

```

[[Return to contents]](#Contents)

## delete_last
```v
fn (mut a array) delete_last()
```

delete_last efficiently deletes the last element of the array. It does it simply by reducing the length of the array by 1. If the array is empty, this will panic. See also: [trim](#array.trim)

[[Return to contents]](#Contents)

## clone
```v
fn (a &array) clone() array
```

clone returns an independent copy of a given array. this will be overwritten by `cgen` with an appropriate call to `.clone_to_depth()` However the `checker` needs it here.

[[Return to contents]](#Contents)

## clone_to_depth
```v
fn (a &array) clone_to_depth(depth int) array
```

recursively clone given array - `unsafe` when called directly because depth is not checked

[[Return to contents]](#Contents)

## push_many
```v
fn (mut a array) push_many(val voidptr, size int)
```

push_many implements the functionality for pushing another array. `val` is array.data and user facing usage is `a << [1,2,3]`

[[Return to contents]](#Contents)

## reverse_in_place
```v
fn (mut a array) reverse_in_place()
```

reverse_in_place reverses existing array data, modifying original array.

[[Return to contents]](#Contents)

## reverse
```v
fn (a array) reverse() array
```

reverse returns a new array with the elements of the original array in reverse order.

[[Return to contents]](#Contents)

## free
```v
fn (a &array) free()
```

free frees all memory occupied by the array.

[[Return to contents]](#Contents)

## filter
```v
fn (a array) filter(predicate fn (voidptr) bool) array
```

filter creates a new array with all elements that pass the test. Ignore the function signature. `filter` does not take an actual callback. Rather, it takes an `it` expression.

Certain array functions (`filter` `any` `all`) support a simplified domain-specific-language by the backend compiler to make these operations more idiomatic to V. These functions are described here, but their implementation is compiler specific.

Each function takes a boolean test expression as its single argument. These test expressions may use `it` as a pointer to a single element at a time.



Examples
```v

a := [10,20,30,3,5,99]; assert a.filter(it < 5) == [3] // create an array of elements less than 5

a := [10,20,30,3,5,99]; assert a.filter(it % 2 == 1) == [3,5,99] // create an array of only odd elements

struct Named { name string }; a := [Named{'Abc'}, Named{'Bcd'}, Named{'Az'}]; assert a.filter(it.name[0] == `A`).len == 2

```

[[Return to contents]](#Contents)

## any
```v
fn (a array) any(predicate fn (voidptr) bool) bool
```

any tests whether at least one element in the array passes the test. Ignore the function signature. `any` does not take an actual callback. Rather, it takes an `it` expression. It returns `true` if it finds an element passing the test. Otherwise, it returns `false`. It doesn't modify the array.



Examples
```v

a := [2,3,4]; assert a.any(it % 2 == 1) // 3 is odd, so this will pass

struct Named { name string }; a := [Named{'Bob'}, Named{'Bilbo'}]; assert a.any(it.name == 'Bob') // the first element will match

```

[[Return to contents]](#Contents)

## count
```v
fn (a array) count(predicate fn (voidptr) bool) int
```

count counts how many elements in array pass the test. Ignore the function signature. `count` does not take an actual callback. Rather, it takes an `it` expression.



Example
```v

a := [10,3,5,7]; assert a.count(it % 2 == 1) == 3 // will return how many elements are odd

```

[[Return to contents]](#Contents)

## all
```v
fn (a array) all(predicate fn (voidptr) bool) bool
```

all tests whether all elements in the array pass the test. Ignore the function signature. `all` does not take an actual callback. Rather, it takes an `it` expression. It returns `false` if any element fails the test. Otherwise, it returns `true`. It doesn't modify the array.



Example
```v

a := [3,5,7,9]; assert a.all(it % 2 == 1) // will return true if every element is odd

```

[[Return to contents]](#Contents)

## map
```v
fn (a array) map(callback fn (voidptr) voidptr) array
```

map creates a new array populated with the results of calling a provided function on every element in the calling array. It also accepts an `it` expression.



Example
```v

words := ['hello', 'world']
r1 := words.map(it.to_upper())
assert r1 == ['HELLO', 'WORLD']

// map can also accept anonymous functions
r2 := words.map(fn (w string) string {
	return w.to_upper()
})
assert r2 == ['HELLO', 'WORLD']

```

[[Return to contents]](#Contents)

## sort
```v
fn (mut a array) sort(callback fn (voidptr, voidptr) int)
```

sort sorts the array in place. Ignore the function signature. Passing a callback to `.sort` is not supported for now. Consider using the `.sort_with_compare` method if you need it.

sort can take a boolean test expression as its single argument. The expression uses 2 'magic' variables `a` and `b` as pointers to the two elements being compared.



Examples
```v

mut aa := [5,2,1,10]; aa.sort(); assert aa == [1,2,5,10] // will sort the array in ascending order

mut aa := [5,2,1,10]; aa.sort(b < a); assert aa == [10,5,2,1] // will sort the array in descending order

struct Named { name string }; mut aa := [Named{'Abc'}, Named{'Xyz'}]; aa.sort(b.name < a.name); assert aa.map(it.name) == ['Xyz','Abc'] // will sort descending by the .name field

```

[[Return to contents]](#Contents)

## sorted
```v
fn (a &array) sorted(callback fn (voidptr, voidptr) int) array
```

sorted returns a sorted copy of the original array. The original array is *NOT* modified. See also .sort() .

Examples
```v

assert [9,1,6,3,9].sorted() == [1,3,6,9,9]

assert [9,1,6,3,9].sorted(b < a) == [9,9,6,3,1]

```

[[Return to contents]](#Contents)

## sort_with_compare
```v
fn (mut a array) sort_with_compare(callback fn (voidptr, voidptr) int)
```

sort_with_compare sorts the array in-place using the results of the given function to determine sort order.

The function should return one of three values:- `-1` when `a` should come before `b` ( `a < b` )
- `1`  when `b` should come before `a` ( `b < a` )
- `0`  when the order cannot be determined ( `a == b` )



Example
```v

mut a := ['hi', '1', '5', '3']
a.sort_with_compare(fn (a &string, b &string) int {
		if a < b {
			return -1
		}
		if a > b {
			return 1
		}
		return 0
})
assert a == ['1', '3', '5', 'hi']

```

[[Return to contents]](#Contents)

## sorted_with_compare
```v
fn (a &array) sorted_with_compare(callback fn (voidptr, voidptr) int) array
```

sorted_with_compare sorts a clone of the array. The original array is not modified. It uses the results of the given function to determine sort order. See also .sort_with_compare()

[[Return to contents]](#Contents)

## contains
```v
fn (a array) contains(value voidptr) bool
```

contains determines whether an array includes a certain value among its elements. It will return `true` if the array contains an element with this value. It is similar to `.any` but does not take an `it` expression.



Example
```v

assert [1, 2, 3].contains(4) == false

```

[[Return to contents]](#Contents)

## index
```v
fn (a array) index(value voidptr) int
```

index returns the first index at which a given element can be found in the array or `-1` if the value is not found.

[[Return to contents]](#Contents)

## grow_cap
```v
fn (mut a array) grow_cap(amount int)
```

grow_cap grows the array's capacity by `amount` elements. Internally, it does this by copying the entire array to a new memory location (creating a clone).

[[Return to contents]](#Contents)

## grow_len
```v
fn (mut a array) grow_len(amount int)
```

grow_len ensures that an array has a.len + amount of length Internally, it does this by copying the entire array to a new memory location (creating a clone) unless the array.cap is already large enough.

[[Return to contents]](#Contents)

## pointers
```v
fn (a array) pointers() []voidptr
```

pointers returns a new array, where each element is the address of the corresponding element in the array.

[[Return to contents]](#Contents)

## map
```v
struct map {
	// Number of bytes of a key
	key_bytes int
	// Number of bytes of a value
	value_bytes int
mut:
	// Highest even index in the hashtable
	even_index u32
	// Number of cached hashbits left for rehashing
	cached_hashbits u8
	// Used for right-shifting out used hashbits
	shift u8
	// Array storing key-values (ordered)
	key_values DenseArray
	// Pointer to meta-data:
	// - Odd indices store kv_index.
	// - Even indices store probe_count and hashbits.
	metas &u32
	// Extra metas that allows for no ranging when incrementing
	// index in the hashmap
	extra_metas     u32
	has_string_keys bool
	hash_fn         MapHashFn
	key_eq_fn       MapEqFn
	clone_fn        MapCloneFn
	free_fn         MapFreeFn
pub mut:
	// Number of key-values currently in the hashmap
	len int
}
```

map is the internal representation of a V `map` type.

[[Return to contents]](#Contents)

## move
```v
fn (mut m map) move() map
```

move moves the map to a new location in memory. It does this by copying to a new location, then setting the old location to all `0` with `vmemset`

[[Return to contents]](#Contents)

## clear
```v
fn (mut m map) clear()
```

clear clears the map without deallocating the allocated data. It does it by setting the map length to `0`

Example
```v

mut m := {'abc': 'xyz', 'def': 'aaa'}; m.clear(); assert m.len == 0

```

[[Return to contents]](#Contents)

## reserve
```v
fn (mut m map) reserve(meta_bytes u32)
```

reserve memory for the map meta data.

[[Return to contents]](#Contents)

## delete
```v
fn (mut m map) delete(key voidptr)
```

delete removes the mapping of a particular key from the map.

[[Return to contents]](#Contents)

## keys
```v
fn (m &map) keys() array
```

keys returns all keys in the map.

[[Return to contents]](#Contents)

## values
```v
fn (m &map) values() array
```

values returns all values in the map.

[[Return to contents]](#Contents)

## clone
```v
fn (m &map) clone() map
```

clone returns a clone of the `map`.

[[Return to contents]](#Contents)

## free
```v
fn (m &map) free()
```

free releases all memory resources occupied by the `map`.

[[Return to contents]](#Contents)

## string
```v
struct string {
pub:
	str &u8 = 0 // points to a C style 0 terminated string of bytes.
	len int // the length of the .str field, excluding the ending 0 byte. It is always equal to strlen(.str).
mut:
	is_lit int
	// NB string.is_lit is an enumeration of the following:
	// .is_lit == 0 => a fresh string, should be freed by autofree
	// .is_lit == 1 => a literal string from .rodata, should NOT be freed
	// .is_lit == -98761234 => already freed string, protects against double frees.
	// ---------> ^^^^^^^^^ calling free on these is a bug.
	// Any other value means that the string has been corrupted.
}
```



[[Return to contents]](#Contents)

## after
```v
fn (s string) after(sub string) string
```



Todo: deprecate either .all_after_last or .after

Examples
```v

assert '23:34:45.234'.after(':') == '45.234'

assert 'abcd'.after('z') == 'abcd'

```

[[Return to contents]](#Contents)

## after_char
```v
fn (s string) after_char(sub u8) string
```

after_char returns the contents after the first occurrence of `sub` character in the string. If the substring is not found, it returns the full input string.

Examples
```v

assert '23:34:45.234'.after_char(`:`) == '34:45.234'

assert 'abcd'.after_char(`:`) == 'abcd'

```

[[Return to contents]](#Contents)

## all_after
```v
fn (s string) all_after(sub string) string
```

all_after returns the contents after `sub` in the string. If the substring is not found, it returns the full input string.

Examples
```v

assert '23:34:45.234'.all_after('.') == '234'

assert 'abcd'.all_after('z') == 'abcd'

```

[[Return to contents]](#Contents)

## all_after_first
```v
fn (s string) all_after_first(sub string) string
```

all_after_first returns the contents after the first occurrence of `sub` in the string. If the substring is not found, it returns the full input string.

Examples
```v

assert '23:34:45.234'.all_after_first(':') == '34:45.234'

assert 'abcd'.all_after_first('z') == 'abcd'

```

[[Return to contents]](#Contents)

## all_after_last
```v
fn (s string) all_after_last(sub string) string
```

all_after_last returns the contents after the last occurrence of `sub` in the string. If the substring is not found, it returns the full input string.

Examples
```v

assert '23:34:45.234'.all_after_last(':') == '45.234'

assert 'abcd'.all_after_last('z') == 'abcd'

```

[[Return to contents]](#Contents)

## all_before
```v
fn (s string) all_before(sub string) string
```

all_before returns the contents before `sub` in the string. If the substring is not found, it returns the full input string.

Examples
```v

assert '23:34:45.234'.all_before('.') == '23:34:45'

assert 'abcd'.all_before('.') == 'abcd'

```

[[Return to contents]](#Contents)

## all_before_last
```v
fn (s string) all_before_last(sub string) string
```

all_before_last returns the contents before the last occurrence of `sub` in the string. If the substring is not found, it returns the full input string.

Examples
```v

assert '23:34:45.234'.all_before_last(':') == '23:34'

assert 'abcd'.all_before_last('.') == 'abcd'

```

[[Return to contents]](#Contents)

## before
```v
fn (s string) before(sub string) string
```



Todo: deprecate and remove either .before or .all_before

Examples
```v

assert '23:34:45.234'.before('.') == '23:34:45'

assert 'abcd'.before('.') == 'abcd'

```

[[Return to contents]](#Contents)

## bool
```v
fn (s string) bool() bool
```

bool returns `true` if the string equals the word "true" it will return `false` otherwise.

[[Return to contents]](#Contents)

## bytes
```v
fn (s string) bytes() []u8
```

bytes returns the string converted to a byte array.

[[Return to contents]](#Contents)

## camel_to_snake
```v
fn (s string) camel_to_snake() string
```

camel_to_snake convert string from camelCase to snake_case

Examples
```v

assert 'Abcd'.camel_to_snake() == 'abcd'

assert 'aaBB'.camel_to_snake() == 'aa_bb'

assert 'BBaa'.camel_to_snake() == 'bb_aa'

assert 'aa_BB'.camel_to_snake() == 'aa_bb'

```

[[Return to contents]](#Contents)

## capitalize
```v
fn (s string) capitalize() string
```

capitalize returns the string with the first character capitalized.

Example
```v

assert 'hello'.capitalize() == 'Hello'

```

[[Return to contents]](#Contents)

## clone
```v
fn (a string) clone() string
```

clone returns a copy of the V string `a`.

[[Return to contents]](#Contents)

## compare
```v
fn (s string) compare(a string) int
```

compare returns -1 if `s` < `a`, 0 if `s` == `a`, and 1 if `s` > `a`

[[Return to contents]](#Contents)

## contains
```v
fn (s string) contains(substr string) bool
```

contains returns `true` if the string contains `substr`. See also: [`string.index`](#string.index)

[[Return to contents]](#Contents)

## contains_any
```v
fn (s string) contains_any(chars string) bool
```

contains_any returns `true` if the string contains any chars in `chars`.

[[Return to contents]](#Contents)

## contains_any_substr
```v
fn (s string) contains_any_substr(substrs []string) bool
```

contains_any_substr returns `true` if the string contains any of the strings in `substrs`.

[[Return to contents]](#Contents)

## contains_only
```v
fn (s string) contains_only(chars string) bool
```

contains_only returns `true`, if the string contains only the characters in `chars`.

[[Return to contents]](#Contents)

## contains_u8
```v
fn (s string) contains_u8(x u8) bool
```

contains_u8 returns `true` if the string contains the byte value `x`. See also: [`string.index_u8`](#string.index_u8) , to get the index of the byte as well.

[[Return to contents]](#Contents)

## count
```v
fn (s string) count(substr string) int
```

count returns the number of occurrences of `substr` in the string. count returns -1 if no `substr` could be found.

[[Return to contents]](#Contents)

## ends_with
```v
fn (s string) ends_with(p string) bool
```

ends_with returns `true` if the string ends with `p`.

[[Return to contents]](#Contents)

## expand_tabs
```v
fn (s string) expand_tabs(tab_len int) string
```

expand_tabs replaces tab characters (\t) in the input string with spaces to achieve proper column alignment .

Example
```v

assert 'AB\tHello!'.expand_tabs(4) == 'AB  Hello!'

```

[[Return to contents]](#Contents)

## f32
```v
fn (s string) f32() f32
```

f32 returns the value of the string as f32 `'1.0'.f32() == f32(1)`.

[[Return to contents]](#Contents)

## f64
```v
fn (s string) f64() f64
```

f64 returns the value of the string as f64 `'1.0'.f64() == f64(1)`.

[[Return to contents]](#Contents)

## fields
```v
fn (s string) fields() []string
```

fields returns a string array of the string split by `\t` and ` ` .

Examples
```v

assert '\t\tv = v'.fields() == ['v', '=', 'v']

assert '  sss   ssss'.fields() == ['sss', 'ssss']

```

[[Return to contents]](#Contents)

## find_between
```v
fn (s string) find_between(start string, end string) string
```

find_between returns the string found between `start` string and `end` string.

Example
```v

assert 'hey [man] how you doin'.find_between('[', ']') == 'man'

```

[[Return to contents]](#Contents)

## free
```v
fn (s &string) free()
```

free allows for manually freeing the memory occupied by the string

[[Return to contents]](#Contents)

## hash
```v
fn (s string) hash() int
```

hash returns an integer hash of the string.

[[Return to contents]](#Contents)

## hex
```v
fn (s string) hex() string
```

hex returns a string with the hexadecimal representation of the bytes of the string `s` .

[[Return to contents]](#Contents)

## i16
```v
fn (s string) i16() i16
```

i16 returns the value of the string as i16 `'1'.i16() == i16(1)`.

[[Return to contents]](#Contents)

## i32
```v
fn (s string) i32() i32
```

i32 returns the value of the string as i32 `'1'.i32() == i32(1)`.

[[Return to contents]](#Contents)

## i64
```v
fn (s string) i64() i64
```

i64 returns the value of the string as i64 `'1'.i64() == i64(1)`.

[[Return to contents]](#Contents)

## i8
```v
fn (s string) i8() i8
```

i8 returns the value of the string as i8 `'1'.i8() == i8(1)`.

[[Return to contents]](#Contents)

## indent_width
```v
fn (s string) indent_width() int
```

indent_width returns the number of spaces or tabs at the beginning of the string.

Examples
```v

assert '  v'.indent_width() == 2

assert '\t\tv'.indent_width() == 2

```

[[Return to contents]](#Contents)

## index
```v
fn (s string) index(p string) ?int
```

index returns the position of the first character of the first occurrence of the `needle` string in `s`. It will return `none` if the `needle` string can't be found in `s`.

[[Return to contents]](#Contents)

## index_after
```v
fn (s string) index_after(p string, start int) ?int
```

index_after returns the position of the input string, starting search from `start` position.

[[Return to contents]](#Contents)

## index_after_
```v
fn (s string) index_after_(p string, start int) int
```

index_after_ returns the position of the input string, starting search from `start` position.

[[Return to contents]](#Contents)

## index_any
```v
fn (s string) index_any(chars string) int
```

index_any returns the position of any of the characters in the input string - if found.

[[Return to contents]](#Contents)

## index_u8
```v
fn (s string) index_u8(c u8) int
```

index_u8 returns the index of byte `c` if found in the string. index_u8 returns -1 if the byte can not be found.

[[Return to contents]](#Contents)

## int
```v
fn (s string) int() int
```

int returns the value of the string as an integer `'1'.int() == 1`.

[[Return to contents]](#Contents)

## is_ascii
```v
fn (s string) is_ascii() bool
```

is_ascii returns true if all characters belong to the US-ASCII set ([` `..`~`])

[[Return to contents]](#Contents)

## is_bin
```v
fn (str string) is_bin() bool
```

is_bin returns `true` if the string is a binary value.

[[Return to contents]](#Contents)

## is_blank
```v
fn (s string) is_blank() bool
```

is_blank returns true if the string is empty or contains only white-space.

Examples
```v

assert ' '.is_blank()

assert '\t'.is_blank()

assert 'v'.is_blank() == false

```

[[Return to contents]](#Contents)

## is_capital
```v
fn (s string) is_capital() bool
```

is_capital returns `true`, if the first character in the string `s`, is a capital letter, and the rest are NOT.

Examples
```v

assert 'Hello'.is_capital() == true

assert 'HelloWorld'.is_capital() == false

```

[[Return to contents]](#Contents)

## is_hex
```v
fn (str string) is_hex() bool
```

is_hex returns 'true' if the string is a hexadecimal value.

[[Return to contents]](#Contents)

## is_identifier
```v
fn (s string) is_identifier() bool
```

is_identifier checks if a string is a valid identifier (starts with letter/underscore, followed by letters, digits, or underscores)

[[Return to contents]](#Contents)

## is_int
```v
fn (str string) is_int() bool
```

Check if a string is an integer value. Returns 'true' if it is, or 'false' if it is not

[[Return to contents]](#Contents)

## is_lower
```v
fn (s string) is_lower() bool
```

is_lower returns `true`, if all characters in the string are lowercase. It only works when the input is composed entirely from ASCII characters.

Example
```v

assert 'hello developer'.is_lower() == true

```

[[Return to contents]](#Contents)

## is_oct
```v
fn (str string) is_oct() bool
```

Check if a string is an octal value. Returns 'true' if it is, or 'false' if it is not

[[Return to contents]](#Contents)

## is_pure_ascii
```v
fn (s string) is_pure_ascii() bool
```

is_pure_ascii returns whether the string contains only ASCII characters. Note that UTF8 encodes such characters in just 1 byte: 1 byte:  0xxxxxxx 2 bytes: 110xxxxx 10xxxxxx 3 bytes: 1110xxxx 10xxxxxx 10xxxxxx 4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx

[[Return to contents]](#Contents)

## is_title
```v
fn (s string) is_title() bool
```

is_title returns true if all words of the string are capitalized.

Example
```v

assert 'Hello V Developer'.is_title() == true

```

[[Return to contents]](#Contents)

## is_upper
```v
fn (s string) is_upper() bool
```

is_upper returns `true` if all characters in the string are uppercase. It only works when the input is composed entirely from ASCII characters. See also: [`byte.is_capital`](#byte.is_capital)

Example
```v

assert 'HELLO V'.is_upper() == true

```

[[Return to contents]](#Contents)

## last_index
```v
fn (s string) last_index(needle string) ?int
```

last_index returns the position of the first character of the *last* occurrence of the `needle` string in `s`.

[[Return to contents]](#Contents)

## last_index_u8
```v
fn (s string) last_index_u8(c u8) int
```

last_index_u8 returns the index of the last occurrence of byte `c` if it was found in the string.

[[Return to contents]](#Contents)

## len_utf8
```v
fn (s string) len_utf8() int
```

len_utf8 returns the number of runes contained in the string `s`.

[[Return to contents]](#Contents)

## limit
```v
fn (s string) limit(max int) string
```

limit returns a portion of the string, starting at `0` and extending for a given number of characters afterward. 'hello'.limit(2) => 'he' 'hi'.limit(10) => 'hi'

[[Return to contents]](#Contents)

## match_glob
```v
fn (name string) match_glob(pattern string) bool
```

match_glob matches the string, with a Unix shell-style wildcard pattern.

Note: wildcard patterns are NOT the same as regular expressions. They are much simpler, and do not allow backtracking, captures, etc. The special characters used in shell-style wildcards are: `*` - matches everything `?` - matches any single character `[seq]` - matches any of the characters in the sequence `[^seq]` - matches any character that is NOT in the sequence Any other character in `pattern`, is matched 1:1 to the corresponding character in `name`, including / and \. You can wrap the meta-characters in brackets too, i.e. `[?]` matches `?` in the string, and `[*]` matches `*` in the string.

Examples
```v

assert 'ABCD'.match_glob('AB*')

assert 'ABCD'.match_glob('*D')

assert 'ABCD'.match_glob('*B*')

assert !'ABCD'.match_glob('AB')

```

[[Return to contents]](#Contents)

## normalize_tabs
```v
fn (s string) normalize_tabs(tab_len int) string
```

normalize_tabs replaces all tab characters with `tab_len` amount of spaces.

Example
```v

assert '\t\tpop rax\t; pop rax'.normalize_tabs(2) == '    pop rax  ; pop rax'

```

[[Return to contents]](#Contents)

## parse_int
```v
fn (s string) parse_int(_base int, _bit_size int) !i64
```

parse_int interprets a string s in the given base (0, 2 to 36) and bit size (0 to 64) and returns the corresponding value i.

If the base argument is 0, the true base is implied by the string's prefix: 2 for "0b", 8 for "0" or "0o", 16 for "0x", and 10 otherwise. Also, for argument base 0 only, underscore characters are permitted as defined by the Go syntax for integer literals.

The bitSize argument specifies the integer type that the result must fit into. Bit sizes 0, 8, 16, 32, and 64 correspond to int, int8, int16, int32, and int64. If bitSize is below 0 or above 64, an error is returned.

This method directly exposes the `parse_int` function from `strconv` as a method on `string`. For more advanced features, consider calling `strconv.common_parse_int` directly.

[[Return to contents]](#Contents)

## parse_uint
```v
fn (s string) parse_uint(_base int, _bit_size int) !u64
```

parse_uint is like `parse_int` but for unsigned numbers

This method directly exposes the `parse_uint` function from `strconv` as a method on `string`. For more advanced features, consider calling `strconv.common_parse_uint` directly.

[[Return to contents]](#Contents)

## repeat
```v
fn (s string) repeat(count int) string
```

repeat returns a new string with `count` number of copies of the string it was called on.

[[Return to contents]](#Contents)

## replace
```v
fn (s string) replace(rep string, with string) string
```

replace replaces all occurrences of `rep` with the string passed in `with`.

[[Return to contents]](#Contents)

## replace_char
```v
fn (s string) replace_char(rep u8, with u8, repeat int) string
```

replace_char replaces all occurrences of the character `rep` multiple occurrences of the character passed in `with` with respect to `repeat`.

Example
```v

assert '\tHello!'.replace_char(`\t`,` `,8) == '        Hello!'

```

[[Return to contents]](#Contents)

## replace_each
```v
fn (s string) replace_each(vals []string) string
```

replace_each replaces all occurrences of the string pairs given in `vals`.

Example
```v

assert 'ABCD'.replace_each(['B','C/','C','D','D','C']) == 'AC/DC'

```

[[Return to contents]](#Contents)

## replace_once
```v
fn (s string) replace_once(rep string, with string) string
```

replace_once replaces the first occurrence of `rep` with the string passed in `with`.

[[Return to contents]](#Contents)

## reverse
```v
fn (s string) reverse() string
```

reverse returns a reversed string.

Example
```v

assert 'Hello V'.reverse() == 'V olleH'

```

[[Return to contents]](#Contents)

## rsplit
```v
fn (s string) rsplit(delim string) []string
```

rsplit splits the string into an array of strings at the given delimiter, starting from the right. If `delim` is empty the string is split by it's characters.

Examples
```v

assert 'DEF'.rsplit('') == ['F','E','D']

assert 'A B C'.rsplit(' ') == ['C','B','A']

```

[[Return to contents]](#Contents)

## rsplit_any
```v
fn (s string) rsplit_any(delim string) []string
```

rsplit_any splits the string to an array by any of the `delim` chars in reverse order. If the delimiter string is empty then `.rsplit()` is used.

Example
```v

assert "first row\nsecond row".rsplit_any(" \n") == ['row', 'second', 'row', 'first']

```

[[Return to contents]](#Contents)

## rsplit_nth
```v
fn (s string) rsplit_nth(delim string, nth int) []string
```

rsplit_nth splits the string based on the passed `delim` substring in revese order. It returns the first Nth parts. When N=0, return all the splits. The last returned element has the remainder of the string, even if the remainder contains more `delim` substrings.

[[Return to contents]](#Contents)

## rsplit_once
```v
fn (s string) rsplit_once(delim string) ?(string, string)
```

rsplit_once splits the string into a pair of strings at the given delimiter, starting from the right.

Note: rsplit_once returns the string at the left side of the delimiter as first part of the pair.

Example
```v

path, ext := 'file.ts.dts'.rsplit_once('.')?
assert path == 'file.ts'
assert ext == 'dts'

```

[[Return to contents]](#Contents)

## runes
```v
fn (s string) runes() []rune
```

runes returns an array of all the utf runes in the string `s` which is useful if you want random access to them

[[Return to contents]](#Contents)

## runes_iterator
```v
fn (s string) runes_iterator() RunesIterator
```

runes_iterator creates an iterator over all the runes in the given string `s`. It can be used in `for r in s.runes_iterator() {`, as a direct substitute to calling .runes(): `for r in s.runes() {`, which needs an intermediate allocation of an array.

[[Return to contents]](#Contents)

## snake_to_camel
```v
fn (s string) snake_to_camel() string
```

snake_to_camel convert string from snake_case to camelCase

Examples
```v

assert 'abcd'.snake_to_camel() == 'Abcd'

assert 'ab_cd'.snake_to_camel() == 'AbCd'

assert '_abcd'.snake_to_camel() == 'Abcd'

assert '_abcd_'.snake_to_camel() == 'Abcd'

```

[[Return to contents]](#Contents)

## split
```v
fn (s string) split(delim string) []string
```

split splits the string into an array of strings at the given delimiter. If `delim` is empty the string is split by it's characters.

Examples
```v

assert 'DEF'.split('') == ['D','E','F']

assert 'A B C'.split(' ') == ['A','B','C']

```

[[Return to contents]](#Contents)

## split_any
```v
fn (s string) split_any(delim string) []string
```

split_any splits the string to an array by any of the `delim` chars. If the delimiter string is empty then `.split()` is used.

Example
```v

assert "first row\nsecond row".split_any(" \n") == ['first', 'row', 'second', 'row']

```

[[Return to contents]](#Contents)

## split_by_space
```v
fn (s string) split_by_space() []string
```

split_by_space splits the string by whitespace (any of ` `, `\n`, `\t`, `\v`, `\f`, `\r`). Repeated, trailing or leading whitespaces will be omitted.

[[Return to contents]](#Contents)

## split_into_lines
```v
fn (s string) split_into_lines() []string
```

split_into_lines splits the string by newline characters. newlines are stripped. `\r` (MacOS), `\n` (POSIX), and `\r\n` (WinOS) line endings are all supported (including mixed line endings).

Note: algorithm is "greedy", consuming '\r\n' as a single line ending with higher priority than '\r' and '\n' as multiple endings

[[Return to contents]](#Contents)

## split_n
```v
fn (s string) split_n(delim string, n int) []string
```

split_n splits the string based on the passed `delim` substring. It returns the first Nth parts. When N=0, return all the splits. The last returned element has the remainder of the string, even if the remainder contains more `delim` substrings.

[[Return to contents]](#Contents)

## split_nth
```v
fn (s string) split_nth(delim string, nth int) []string
```

split_nth splits the string based on the passed `delim` substring. It returns the first Nth parts. When N=0, return all the splits. The last returned element has the remainder of the string, even if the remainder contains more `delim` substrings.

[[Return to contents]](#Contents)

## split_once
```v
fn (s string) split_once(delim string) ?(string, string)
```

split_once splits the string into a pair of strings at the given delimiter.

Example
```v

path, ext := 'file.ts.dts'.split_once('.')?
assert path == 'file'
assert ext == 'ts.dts'

```

[[Return to contents]](#Contents)

## starts_with
```v
fn (s string) starts_with(p string) bool
```

starts_with returns `true` if the string starts with `p`.

[[Return to contents]](#Contents)

## starts_with_capital
```v
fn (s string) starts_with_capital() bool
```

starts_with_capital returns `true`, if the first character in the string `s`, is a capital letter, even if the rest are not.

Examples
```v

assert 'Hello'.starts_with_capital() == true

assert 'Hello. World.'.starts_with_capital() == true

```

[[Return to contents]](#Contents)

## str
```v
fn (s string) str() string
```

str returns a copy of the string

[[Return to contents]](#Contents)

## strip_margin
```v
fn (s string) strip_margin() string
```

strip_margin allows multi-line strings to be formatted in a way that removes white-space before a delimiter. By default `|` is used.

Note: the delimiter has to be a byte at this time. That means surrounding the value in ``.

See also: string.trim_indent()



Example
```v

st := 'Hello there,
       |  this is a string,
       |  Everything before the first | is removed'.strip_margin()

assert st == 'Hello there,
  this is a string,
  Everything before the first | is removed'

```

[[Return to contents]](#Contents)

## strip_margin_custom
```v
fn (s string) strip_margin_custom(del u8) string
```

strip_margin_custom does the same as `strip_margin` but will use `del` as delimiter instead of `|`

[[Return to contents]](#Contents)

## substr
```v
fn (s string) substr(start int, _end int) string
```

substr returns the string between index positions `start` and `end`.

Example
```v

assert 'ABCD'.substr(1,3) == 'BC'

```

[[Return to contents]](#Contents)

## substr_ni
```v
fn (s string) substr_ni(_start int, _end int) string
```

substr_ni returns the string between index positions `start` and `end` allowing negative indexes This function always return a valid string.

[[Return to contents]](#Contents)

## substr_unsafe
```v
fn (s string) substr_unsafe(start int, _end int) string
```

substr_unsafe works like substr(), but doesn't copy (allocate) the substring

[[Return to contents]](#Contents)

## substr_with_check
```v
fn (s string) substr_with_check(start int, _end int) !string
```

version of `substr()` that is used in `a[start..end] or {` return an error when the index is out of range

[[Return to contents]](#Contents)

## title
```v
fn (s string) title() string
```

title returns the string with each word capitalized.

Example
```v

assert 'hello v developer'.title() == 'Hello V Developer'

```

[[Return to contents]](#Contents)

## to_lower
```v
fn (s string) to_lower() string
```

to_lower returns the string in all lowercase characters.

Example
```v

assert 'Hello V'.to_lower() == 'hello v'

```

[[Return to contents]](#Contents)

## to_lower_ascii
```v
fn (s string) to_lower_ascii() string
```

to_lower_ascii returns the string in all lowercase characters. It is faster than `s.to_lower()`, but works only when the input string `s` is composed *entirely* from ASCII characters. Use `s.to_lower()` instead, if you are not sure.

[[Return to contents]](#Contents)

## to_upper
```v
fn (s string) to_upper() string
```

to_upper returns the string in all uppercase characters.

Example
```v

assert 'Hello V'.to_upper() == 'HELLO V'

```

[[Return to contents]](#Contents)

## to_upper_ascii
```v
fn (s string) to_upper_ascii() string
```

to_upper_ascii returns the string in all UPPERCASE characters. It is faster than `s.to_upper()`, but works only when the input string `s` is composed *entirely* from ASCII characters. Use `s.to_upper()` instead, if you are not sure.

[[Return to contents]](#Contents)

## to_wide
```v
fn (_str string) to_wide() &u16
```

to_wide returns a pointer to an UTF-16 version of the string receiver. In V, strings are encoded using UTF-8 internally, but on windows most APIs, that accept strings, need them to be in UTF-16 encoding. The returned pointer of .to_wide(), has a type of &u16, and is suitable for passing to Windows APIs that expect LPWSTR or wchar_t* parameters. See also MultiByteToWideChar ( https://learn.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar ) See also builtin.wchar.from_string/1, for a version, that produces a platform dependant L"" C style wchar_t* wide string.

[[Return to contents]](#Contents)

## trim
```v
fn (s string) trim(cutset string) string
```

trim strips any of the characters given in `cutset` from the start and end of the string.

Example
```v

assert ' ffHello V ffff'.trim(' f') == 'Hello V'

```

[[Return to contents]](#Contents)

## trim_indent
```v
fn (s string) trim_indent() string
```

trim_indent detects a common minimal indent of all the input lines, removes it from every line and also removes the first and the last lines if they are blank (notice difference blank vs empty).

Note that blank lines do not affect the detected indent level.

In case if there are non-blank lines with no leading whitespace characters (no indent at all) then the common indent is 0, and therefore this function doesn't change the indentation.



Example
```v

st := '
     Hello there,
     this is a string,
     all the leading indents are removed
     and also the first and the last lines if they are blank
'.trim_indent()

assert st == 'Hello there,
this is a string,
all the leading indents are removed
and also the first and the last lines if they are blank'

```

[[Return to contents]](#Contents)

## trim_indexes
```v
fn (s string) trim_indexes(cutset string) (int, int)
```

trim_indexes gets the new start and end indices of a string when any of the characters given in `cutset` were stripped from the start and end of the string. Should be used as an input to `substr()`. If the string contains only the characters in `cutset`, both values returned are zero.

Example
```v

left, right := '-hi-'.trim_indexes('-'); assert left == 1; assert right == 3

```

[[Return to contents]](#Contents)

## trim_left
```v
fn (s string) trim_left(cutset string) string
```

trim_left strips any of the characters given in `cutset` from the left of the string.

Example
```v

assert 'd Hello V developer'.trim_left(' d') == 'Hello V developer'

```

[[Return to contents]](#Contents)

## trim_right
```v
fn (s string) trim_right(cutset string) string
```

trim_right strips any of the characters given in `cutset` from the right of the string.

Example
```v

assert ' Hello V d'.trim_right(' d') == ' Hello V'

```

[[Return to contents]](#Contents)

## trim_space
```v
fn (s string) trim_space() string
```

trim_space strips any of ` `, `\n`, `\t`, `\v`, `\f`, `\r` from the start and end of the string.

Example
```v

assert ' Hello V '.trim_space() == 'Hello V'

```

[[Return to contents]](#Contents)

## trim_space_left
```v
fn (s string) trim_space_left() string
```

trim_space_left strips any of ` `, `\n`, `\t`, `\v`, `\f`, `\r` from the start of the string.

Example
```v

assert ' Hello V '.trim_space_left() == 'Hello V '

```

[[Return to contents]](#Contents)

## trim_space_right
```v
fn (s string) trim_space_right() string
```

trim_space_right strips any of ` `, `\n`, `\t`, `\v`, `\f`, `\r` from the end of the string.

Example
```v

assert ' Hello V '.trim_space_right() == ' Hello V'

```

[[Return to contents]](#Contents)

## trim_string_left
```v
fn (s string) trim_string_left(str string) string
```

trim_string_left strips `str` from the start of the string.

Example
```v

assert 'WorldHello V'.trim_string_left('World') == 'Hello V'

```

[[Return to contents]](#Contents)

## trim_string_right
```v
fn (s string) trim_string_right(str string) string
```

trim_string_right strips `str` from the end of the string.

Example
```v

assert 'Hello VWorld'.trim_string_right('World') == 'Hello V'

```

[[Return to contents]](#Contents)

## u16
```v
fn (s string) u16() u16
```

u16 returns the value of the string as u16 `'1'.u16() == u16(1)`.

[[Return to contents]](#Contents)

## u32
```v
fn (s string) u32() u32
```

u32 returns the value of the string as u32 `'1'.u32() == u32(1)`.

[[Return to contents]](#Contents)

## u64
```v
fn (s string) u64() u64
```

u64 returns the value of the string as u64 `'1'.u64() == u64(1)`.

[[Return to contents]](#Contents)

## u8
```v
fn (s string) u8() u8
```

u8 returns the value of the string as u8 `'1'.u8() == u8(1)`.

[[Return to contents]](#Contents)

## u8_array
```v
fn (s string) u8_array() []u8
```

u8_array returns the value of the hex/bin string as u8 array. hex string example: `'0x11223344ee'.u8_array() == [u8(0x11),0x22,0x33,0x44,0xee]`. bin string example: `'0b1101_1101'.u8_array() == [u8(0xdd)]`. underscore in the string will be stripped.

[[Return to contents]](#Contents)

## uncapitalize
```v
fn (s string) uncapitalize() string
```

uncapitalize returns the string with the first character uncapitalized.

Example
```v

assert 'Hello, Bob!'.uncapitalize() == 'hello, Bob!'

```

[[Return to contents]](#Contents)

## utf32_code
```v
fn (_rune string) utf32_code() int
```

Convert utf8 to utf32 the original implementation did not check for valid utf8 in the string, and could result in values greater than the utf32 spec it has been replaced by `utf8_to_utf32` which has an option return type.

this function is left for backward compatibility it is used in vlib/builtin/string.v, and also in vlib/v/gen/c/cgen.v

[[Return to contents]](#Contents)

## wrap
```v
fn (s string) wrap(config WrapConfig) string
```

wrap wraps the string `s` when each line exceeds the width specified in `width` . (default value is 80), and will use `end` (default value is '\n') as a line break.

Example
```v

assert 'Hello, my name is Carl and I am a delivery'.wrap(width: 20) == 'Hello, my name is\nCarl and I am a\ndelivery'

```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:39
