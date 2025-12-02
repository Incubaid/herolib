module meta

@[heap]
struct Category {
pub mut:
	path        string // e.g. Operations/Daily (means 2 levels deep, first level is Operations)
	collapsible bool = true
	collapsed   bool
	items       []CategoryItem
}

//return the label of the category (last part of the path)
pub fn (mut c Category) label() !string {
	if c.path.count('/') == 0 {
		return c.path
	}
	return c.path.all_after_last('/')
}

type CategoryItem = Page | Link | Category



pub fn (mut self Category) up(path string) !&Category {
	// Split the requested path into parts
	path_parts := path.split('/')
	
	// Start at current category
	mut current := &self
	
	// Navigate through each part of the path
	for part in path_parts {
		// Skip empty parts (from leading/trailing slashes)
		if part.len == 0 {
			continue
		}
		
		// Check if this part already exists in current category's items
		mut found := false
		for item in current.items {
			match item {
				&Category {
					item_label := item.label()!
					if item_label == part {
						current = item
						found = true
						break
					}
				}
				else {}
			}
		}
		
		// If not found, create a new category and add it
		if !found {
			mut new_category := Category{
				path:        part
				collapsible: true
				collapsed:   true
				items:       []CategoryItem{}
			}
			current.items << new_category
			current = &new_category
		}
	}
	
	return current
}


fn (mut self Category) page_get(src string)! &Page {
	for item in self.items {
		match item {
			Page {
				if item.src == src {
					return it
				}
			}
			else {}
		}
	}
	return error('Page with src="${src}" not found in site.')
}

fn (mut self Category) link_get(href string)! &Link {
	for item in self.items {
		match item {
			Link {
				if item.href == href {
					return it
				}
			}
			else {}
		}
	}
	return error('Link with href="${href}" not found in site.')
}

fn (mut self Category) category_get(path string)! &Category {
	for item in self.items {
		match item {
			Category {
				if item.path == path {
					return it
				}
			}
			else {}
		}
	}
	return error('Category with path="${path}" not found in site.')
}