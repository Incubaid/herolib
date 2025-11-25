module filemap

// BlockKind defines the type of block in parsed content
pub enum BlockKind {
	file
	filechange
	end
}

pub struct FMError {
pub:
	message  string
	linenr   int
	category string
	filename string
}
