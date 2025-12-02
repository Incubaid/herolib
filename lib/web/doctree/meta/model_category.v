module meta

@[heap]
struct Category {
pub mut:
	path        string // e.g. Operations/Daily (means 2 levels deep, first level is Operations)
	collapsible bool = true
	collapsed   bool
	items       []CategoryItem
}

// return the label of the category (last part of the path)
pub fn (mut c Category) label() !string {
	if c.path.count('/') == 0 {
		return c.path
	}
	return c.path.all_after_last('/')
}

type CategoryItem = Page | Link | Category

// return all items as CategoryItem references recursive
pub fn (mut self Category) items_get() ![]&CategoryItem {
	mut result := []&CategoryItem{}
	for i in 0 .. self.items.len {
		mut c := self.items[i]
		match mut c {
			Category {
				result << c.items_get()!
			}
			else {
				result << &c
			}
		}
	}
	return result
}

pub fn (mut self Category) page_get(src string) !&Page {
	for c in self.items_get()! {
		match c {
			Page {
				if c.src == src {
					return &c
				}
			}
			else {}
		}
	}
	return error('Page with src="${src}" not found in site.')
}

pub fn (mut self Category) link_get(href string) !&Link {
	for c in self.items_get()! {
		match c {
			Link {
				if c.href == href {
					return &c
				}
			}
			else {}
		}
	}
	return error('Link with href="${href}" not found in site.')
}

pub fn (mut self Category) category_get(path string) !&Category {
	for i in 0 .. self.items.len {
		mut c := self.items[i]
		match mut c {
			Category {
				if c.path == path {
					return &c
				}
			}
			else {}
		}
	}
	mut new_category := Category{
		path:        path
		collapsible: true
		collapsed:   true
		items:       []CategoryItem{}
	}
	// Add the new category as a sum type variant
	self.items << new_category
	// Update current_category_ref to point to the newly added category in the slice
	return &new_category
}
