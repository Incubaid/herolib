# module html


## Contents
- [escape](#escape)
- [unescape](#unescape)
- [EscapeConfig](#EscapeConfig)
- [UnescapeConfig](#UnescapeConfig)

## escape
```v
fn escape(input string, config EscapeConfig) string
```

escape converts special characters in the input, specifically "<", ">", and "&" to HTML-safe sequences. If `quote` is set to true (which is default), quotes in HTML will also be translated. Both double and single quotes will be affected. **Note:** escape() supports funky accents by doing nothing about them. V's UTF-8 support through `string` is robust enough to deal with these cases.

[[Return to contents]](#Contents)

## unescape
```v
fn unescape(input string, config UnescapeConfig) string
```

unescape converts entities like "&lt;" to "<". By default it is the converse of `escape`. If `all` is set to true, it handles named, numeric, and hex values - for example, `'&apos;'`, `'&#39;'`, and `'&#x27;'` then unescape to "'".

[[Return to contents]](#Contents)

## EscapeConfig
```v
struct EscapeConfig {
pub:
	quote bool = true
}
```

[[Return to contents]](#Contents)

## UnescapeConfig
```v
struct UnescapeConfig {
	EscapeConfig
pub:
	all bool
}
```

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
