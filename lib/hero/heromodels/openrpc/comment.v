module openrpc

import json
import freeflowuniverse.herolib.hero.heromodels

// Comment-specific argument structures
@[params]
pub struct CommentGetArgs {
pub mut:
	id     ?u32
	author ?u32
	parent ?u32
}

@[params]
pub struct CommentDeleteArgs {
pub mut:
	id u32
}

// comment_get retrieves comments based on the provided arguments
pub fn comment_get(params string) !string {
	// Handle empty params
	if params == 'null' || params == '{}' {
		return error('No valid search criteria provided. Please specify id, author, or parent.')
	}

	args := json.decode(CommentGetArgs, params)!

	// If ID is provided, get specific comment
	if id := args.id {
		comment := heromodels.comment_get(id)!
		return json.encode(comment)
	}

	// If author is provided, find comments by author
	if author := args.author {
		return get_comments_by_author(author)!
	}

	// If parent is provided, find child comments
	if parent := args.parent {
		return get_comments_by_parent(parent)!
	}

	return error('No valid search criteria provided. Please specify id, author, or parent.')
}

// comment_set creates or updates a comment
pub fn comment_set(params string) !string {
	comment_arg := json.decode(heromodels.CommentArgExtended, params)!
	id := heromodels.comment_set(comment_arg)!
	return json.encode({
		'id': id
	})
}

// comment_delete removes a comment by ID
pub fn comment_delete(params string) !string {
	args := json.decode(CommentDeleteArgs, params)!

	// Check if comment exists
	if !heromodels.exists[heromodels.Comment](args.id)! {
		return error('Comment with id ${args.id} does not exist')
	}

	// Delete using core method
	heromodels.delete[heromodels.Comment](args.id)!

	result_json := '{"success": true, "id": ${args.id}}'
	return result_json
}

// comment_list returns all comment IDs
pub fn comment_list() !string {
	comments := heromodels.list[heromodels.Comment]()!
	mut ids := []u32{}

	for comment in comments {
		ids << comment.id
	}

	return json.encode(ids)
}

// Helper function to get comments by author
fn get_comments_by_author(author u32) !string {
	all_comments := heromodels.list[heromodels.Comment]()!
	mut matching_comments := []heromodels.Comment{}

	for comment in all_comments {
		if comment.author == author {
			matching_comments << comment
		}
	}

	return json.encode(matching_comments)
}

// Helper function to get comments by parent
fn get_comments_by_parent(parent u32) !string {
	all_comments := heromodels.list[heromodels.Comment]()!
	mut matching_comments := []heromodels.Comment{}

	for comment in all_comments {
		if comment.parent == parent {
			matching_comments << comment
		}
	}

	return json.encode(matching_comments)
}
