module atlas

import incubaid.herolib.core.pathlib

pub enum FileType {
    file
    image
}

pub struct File {
pub mut:
    name  string           // name without extension
    ext   string           // file extension
    path  pathlib.Path     // full path to file
    ftype FileType         // file or image
}

@[params]
pub struct NewFileArgs {
pub:
    path pathlib.Path @[required]
}

pub fn new_file(args NewFileArgs) !File {
    mut f := File{
        path: args.path
    }
    f.init()!
    return f
}

fn (mut f File) init() ! {
    // Determine file type
    if f.path.is_image() {
        f.ftype = .image
    } else {
        f.ftype = .file
    }
    
    // Extract name and extension
    f.name = f.path.name_fix_no_ext()
    f.ext = f.path.extension_lower()
}

pub fn (f File) file_name() string {
    return '${f.name}.${f.ext}'
}

pub fn (f File) is_image() bool {
    return f.ftype == .image
}