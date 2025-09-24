module codewalker

pub struct CWError {
pub:
	message  string
	linenr   int
	category string
}

pub struct FMError {
pub:
	message  string
	linenr   int // is optional
	category string
	filename string
}
