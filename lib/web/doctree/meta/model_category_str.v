module meta

pub fn (mut self Category) str() string {
	mut result := []string{}

	if self.items.len == 0 {
		return 'Sidebar is empty\n'
	}

	result << '📑 SIDEBAR STRUCTURE'
	result << '━'.repeat(60)

	for i, item in self.items {
		is_last := i == self.items.len - 1
		prefix := if is_last { '└── ' } else { '├── ' }

		match item {
			NavDoc {
				result << '${prefix}📄 ${item.label}'
				result << '    └─ path: ${item.path}'
			}
			NavCat {
				// Category header
				collapse_icon := if item.collapsed { '▶ ' } else { '▼ ' }
				result << '${prefix}${collapse_icon}📁 ${item.label}'

				// Category metadata
				if !item.collapsed {
					result << '    ├─ collapsible: ${item.collapsible}'
					result << '    └─ items: ${item.items.len}'

					// Sub-items
					for j, sub_item in item.items {
						is_last_sub := j == item.items.len - 1
						sub_prefix := if is_last_sub { '    └── ' } else { '    ├── ' }

						match sub_item {
							NavDoc {
								result << '${sub_prefix}📄 ${sub_item.label} [${sub_item.src_path}]'
							}
							NavCat {
								// Nested categories
								sub_collapse_icon := if sub_item.collapsed { '▶ ' } else { '▼ ' }
								result << '${sub_prefix}${sub_collapse_icon}📁 ${sub_item.label}'
							}
							NavLink {
								result << '${sub_prefix}🔗 ${sub_item.label}'
								if sub_item.description.len > 0 {
									result << '         └─ ${sub_item.description}'
								}
							}
						}
					}
				}
			}
			NavLink {
				result << '${prefix}🔗 ${item.label}'
				result << '    └─ href: ${item.href}'
				if item.description.len > 0 {
					result << '    └─ desc: ${item.description}'
				}
			}
		}

		// Add spacing between root items
		if i < self.items.len - 1 {
			result << ''
		}
	}

	result << '━'.repeat(60)
	result << '📊 SUMMARY'
	result << '  Total items: ${self.items.len}'

	return result.join('\n') + '\n'
}
