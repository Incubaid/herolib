module atlas

import incubaid.herolib.core.pathlib

pub struct Page {
pub mut:
    name            string         // name without extension
    path            pathlib.Path   // full path to markdown file
    collection_name string         // parent collection name
}

@[params]
pub struct NewPageArgs {
pub:
    name            string       @[required]
    path            pathlib.Path @[required]
    collection_name string       @[required]
}

pub fn new_page(args NewPageArgs) !Page {
    return Page{
        name:            args.name
        path:            args.path
        collection_name: args.collection_name
    }
}

// Simple content reading (no processing)
pub fn (mut p Page) read_content() !string {
    return p.path.read()!
}

pub fn (p Page) key() string {
    return '${p.collection_name}:${p.name}'
}