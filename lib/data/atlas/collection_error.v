module atlas

pub enum CollectionErrorCategory {
    missing_include
    include_syntax_error
    circular_include
    page_not_found
    file_not_found
    collection_not_found
    other
}

pub struct CollectionError {
pub:
    page_key string // "collection:page_name" if applicable
    message  string
    category CollectionErrorCategory
}

pub fn (e CollectionError) markdown() string {
    return 'ERROR [${e.category.str()}]: ${e.message}' + (if e.page_key != '' { ' (Page: `${e.page_key}`)' } else { '' })
}