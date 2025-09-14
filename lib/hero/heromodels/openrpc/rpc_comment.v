module openrpc

import json
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.hero.db

// Comment-specific argument structures
@[params]
pub struct CommentGetArgs {
pub mut:
	id u32 @[required]
}

@[params]
pub struct CommentListArgs {
pub mut:
	// Optional filters for author or parent can be added here if needed
	// For now, list will return all comments
	author ?u32
	parent ?u32
}

@[params]
pub struct CommentDeleteArgs {
pub mut:
	id u32 @[required]
}

pub fn comment_get(params string) !string {
	args := json.decode(CommentGetArgs, params)!
	mut mydb := heromodels.new()!
	comment := mydb.comments.get(args.id)!
	return json.encode(comment)
}

pub fn comment_set(params string) !string {
	comment_arg := json.decode(db.CommentArg, params)!
	mut mydb := heromodels.new()!
	mut o := mydb.comments.new(comment_arg)!
	id := mydb.comments.set(o)!
	return json.encode({'id': id})
}

pub fn comment_delete(params string) !string {
	args := json.decode(CommentDeleteArgs, params)!
	mut mydb := heromodels.new()!

	// Check if comment exists
	if !mydb.comments.exist(args.id)! {
		return error('Comment with id ${args.id} does not exist')
	}

	// Delete using core method
	mydb.comments.delete(args.id)!

	result_json := '{"success": true, "id": ${args.id}}'
	return result_json
}

pub fn comment_list(params string) !string {
	// params is currently ignored, but kept for future filtering capabilities
	// args := json.decode(CommentListArgs, params)!
	mut mydb := heromodels.new()!
	comments := mydb.comments.list()!
	return json.encode(comments)
}