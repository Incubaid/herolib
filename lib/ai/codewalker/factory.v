module codewalker

// new creates a CodeWalker instance with default ignore patterns
pub fn new() CodeWalker {
	return CodeWalker{
		scoped_ignore: ScopedIgnore{}
	}
}

// filemap creates FileMap from path or content (convenience function)
pub fn filemap(args FileMapArgs) !FileMap {
	mut cw := new()
	return cw.filemap_get(args)
}
