module filemap

@[params]
pub struct FileMapArgs {
pub mut:
	path         string
	content      string
	content_read bool = true // If false, file content not read from disk
	// Include if matches any wildcard pattern (* = any sequence)
	filter []string
	// Exclude if matches any wildcard pattern
	filter_ignore []string
}

// filemap_get creates FileMap from path or content string
pub fn filemap(args FileMapArgs) !FileMap {
	if args.path != '' {
		return filemap_get_from_path(args.path, args.content_read)!
	} else if args.content != '' {
		return filemap_get_from_content(args.content)!
	} else {
		return error('Either path or content must be provided')
	}
}
