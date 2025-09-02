# module encoding.utf8.east_asian


## Contents
- [display_width](#display_width)
- [east_asian_width_property_at](#east_asian_width_property_at)
- [EastAsianWidthProperty](#EastAsianWidthProperty)

## display_width
```v
fn display_width(s string, ambiguous_width int) int
```

display_width return the display width as number of unicode chars from a string.

[[Return to contents]](#Contents)

## east_asian_width_property_at
```v
fn east_asian_width_property_at(s string, index int) EastAsianWidthProperty
```

width_property_at returns the East Asian Width properties at string[index]

[[Return to contents]](#Contents)

## EastAsianWidthProperty
```v
enum EastAsianWidthProperty {
	full
	half
	wide
	narrow
	ambiguous
	neutral
}
```

EastAsianWidthType represents East_Asian_Width informative prorperty

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:04
