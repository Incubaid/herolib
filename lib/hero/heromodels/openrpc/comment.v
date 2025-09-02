module openrpc

import json
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.core.redisclient

// comment_get retrieves comments based on the provided arguments
fn (mut server RPCServer) comment_get(params string) !string {
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
		return server.get_comments_by_author(author)!
	}
	
	// If parent is provided, find child comments
	if parent := args.parent {
		return server.get_comments_by_parent(parent)!
	}
	
	return error('No valid search criteria provided. Please specify id, author, or parent.')
}

// comment_set creates or updates a comment
fn (mut server RPCServer) comment_set(params string) !string {
	comment_arg := json.decode(heromodels.CommentArg, params)!
	id := heromodels.comment_set(comment_arg)!
	return json.encode({'id': id})
}

// comment_delete removes a comment by ID
fn (mut server RPCServer) comment_delete(params string) !string {
	args := json.decode(CommentDeleteArgs, params)!
	
	// Check if comment exists
	if !heromodels.comment_exist(args.id)! {
		return error('Comment with id ${args.id} does not exist')
	}
	
	// Delete from Redis
	mut redis := redisclient.core_get()!
	redis.hdel('db:comments:data', args.id.str())!
	
	result_json := '{"success": true, "id": ${args.id}}'
	return result_json
}

// comment_list returns all comment IDs
fn (mut server RPCServer) comment_list() !string {
	mut redis := redisclient.core_get()!
	keys := redis.hkeys('db:comments:data')!
	mut ids := []u32{}
	
	for key in keys {
		ids << key.u32()
	}
	
	return json.encode(ids)
}

// Helper function to get comments by author
fn (mut server RPCServer) get_comments_by_author(author u32) !string {
	mut redis := redisclient.core_get()!
	all_data := redis.hgetall('db:comments:data')!
	mut matching_comments := []heromodels.Comment{}
	
	for _, data in all_data {
		comment := heromodels.comment_load(data.bytes())!
		if comment.author == author {
			matching_comments << comment
		}
	}
	
	return json.encode(matching_comments)
}

// Helper function to get comments by parent
fn (mut server RPCServer) get_comments_by_parent(parent u32) !string {
	mut redis := redisclient.core_get()!
	all_data := redis.hgetall('db:comments:data')!
	mut matching_comments := []heromodels.Comment{}
	
	for _, data in all_data {
		comment := heromodels.comment_load(data.bytes())!
		if comment.parent == parent {
			matching_comments << comment
		}
	}
	
	return json.encode(matching_comments)
}