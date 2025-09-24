module core

// Comment represents a generic commenting functionality that can be associated with any other model
// It supports threaded conversations through parent_comment_id
@[heap]
pub struct Comment {
pub mut:
	id                u32    // Unique comment ID
	user_id           u32    // ID of the user who posted the comment (indexed)
	content           string // The text content of the comment
	parent_comment_id ?u32   // Optional parent comment ID for threaded comments
	created_at        u64    // Creation timestamp
	updated_at        u64    // Last update timestamp
}

// new creates a new Comment with default values
pub fn Comment.new() Comment {
	return Comment{
		id:                0
		user_id:           0
		content:           ''
		parent_comment_id: none
		created_at:        0
		updated_at:        0
	}
}

// user_id sets the user ID for the comment (builder pattern)
pub fn (mut c Comment) user_id(id u32) Comment {
	c.user_id = id
	return c
}

// content sets the content for the comment (builder pattern)
pub fn (mut c Comment) content(text string) Comment {
	c.content = text
	return c
}

// parent_comment_id sets the parent comment ID for threaded comments (builder pattern)
pub fn (mut c Comment) parent_comment_id(parent_id ?u32) Comment {
	c.parent_comment_id = parent_id
	return c
}

// is_top_level returns true if this is a top-level comment (no parent)
pub fn (c Comment) is_top_level() bool {
	return c.parent_comment_id == none
}

// is_reply returns true if this is a reply to another comment
pub fn (c Comment) is_reply() bool {
	return c.parent_comment_id != none
}
