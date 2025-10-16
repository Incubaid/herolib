module atlas

pub struct CollectionNotFound {
    Error
pub:
    name string
    msg  string
}

pub fn (err CollectionNotFound) msg() string {
    return 'Collection ${err.name} not found: ${err.msg}'
}

pub struct PageNotFound {
    Error
pub:
    collection string
    page       string
}

pub fn (err PageNotFound) msg() string {
    return 'Page ${err.page} not found in collection ${err.collection}'
}

pub struct FileNotFound {
    Error
pub:
    collection string
    file       string
}

pub fn (err FileNotFound) msg() string {
    return 'File ${err.file} not found in collection ${err.collection}'
}