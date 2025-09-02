module openrpc

import x.json2
import freeflowuniverse.herolib.hero.heromodels
import freeflowuniverse.herolib.core.redisclient

// comment_get retrieves comments based on the provided arguments
fn (mut server RPCServer) comment_get(params json2.Any) !json2.Any {
	args := json2.decode[CommentGetArgs](params.json_str())!
	
	// If ID is provided, get specific comment
	if id := args.id {
		comment := heromodels.comment_get(id)!
		return json2.encode(comment)
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
fn (mut server RPCServer) comment_set(params json2.Any) !json2.Any {
	comment_arg := json2.decode[heromodels.CommentArg](params.json_str())!
	id := heromodels.comment_set(comment_arg)!
	return json2.encode({'id': id})
}

// comment_delete removes a comment by ID
fn (mut server RPCServer) comment_delete(params json2.Any) !json2.Any {
	args := json2.decode[CommentDeleteArgs](params.json_str())!
	
	// Check if comment exists
	if !heromodels.comment_exist(args.id)! {
		return error('Comment with id ${args.id} does not exist')
	}
	
	// Delete from Redis
	mut redis := redisclient.core_get()!
	redis.hdel('db:comments:data', args.id.str())!
	
	result_json := '{"success": true, "id": ${args.id}}'
	return json2.raw_decode(result_json)!
}

// comment_list returns all comment IDs
fn (mut server RPCServer) comment_list() !json2.Any {
	mut redis := redisclient.core_get()!
	keys := redis.hkeys('db:comments:data')!
	mut ids := []u32{}
	
	for key in keys {
		ids << key.u32()
	}
	
	return json2.encode(ids)
}

// Helper function to get comments by author
fn (mut server RPCServer) get_comments_by_author(author u32) !json2.Any {
	mut redis := redisclient.core_get()!
	all_data := redis.hgetall('db:comments:data')!
	mut matching_comments := []heromodels.Comment{}
	
	for _, data in all_data {
		comment := heromodels.comment_load(data.bytes())!
		if comment.author == author {
			matching_comments << comment
		}
	}
	
	return json2.encode(matching_comments)
}

// Helper function to get comments by parent
fn (mut server RPCServer) get_comments_by_parent(parent u32) !json2.Any {
	mut redis := redisclient.core_get()!
	all_data := redis.hgetall('db:comments:data')!
	mut matching_comments := []heromodels.Comment{}
	
	for _, data in all_data {
		comment := heromodels.comment_load(data.bytes())!
		if comment.parent == parent {
			matching_comments << comment
		}
	}
	
	return json2.encode(matching_comments)
}