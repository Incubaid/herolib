#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module heromodels

import freeflowuniverse.herolib.hero.heromodels

// Test Comment model CRUD operations
fn test_comment_new() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Test creating a new comment with all fields
	mut comment := mydb.comments.new(
		comment: 'This is a test comment'
		parent: 0
		author: 123
	) or { panic('Failed to create comment: ${err}') }
	
	// Verify the comment was created with correct values
	assert comment.comment == 'This is a test comment'
	assert comment.parent == 0
	assert comment.author == 123
	assert comment.id == 0 // Should be 0 before saving
	assert comment.updated_at > 0 // Should have timestamp
}

fn test_comment_set_and_get() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Create a comment
	mut comment := mydb.comments.new(
		comment: 'Hello, this is my first comment!'
		parent: 0
		author: 456
	) or { panic('Failed to create comment: ${err}') }
	
	// Save the comment
	mydb.comments.set(mut comment) or { panic('Failed to save comment: ${err}') }
	
	// Verify ID was assigned
	assert comment.id > 0
	original_id := comment.id
	
	// Retrieve the comment
	retrieved_comment := mydb.comments.get(comment.id) or { panic('Failed to get comment: ${err}') }
	
	// Verify all fields match
	assert retrieved_comment.id == original_id
	assert retrieved_comment.comment == 'Hello, this is my first comment!'
	assert retrieved_comment.parent == 0
	assert retrieved_comment.author == 456
	assert retrieved_comment.created_at > 0
	assert retrieved_comment.updated_at > 0
}

fn test_comment_reply() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Create a parent comment
	mut parent_comment := mydb.comments.new(
		comment: 'This is the parent comment'
		parent: 0
		author: 100
	) or { panic('Failed to create parent comment: ${err}') }
	
	mydb.comments.set(mut parent_comment) or { panic('Failed to save parent comment: ${err}') }
	parent_id := parent_comment.id
	
	// Create a reply comment
	mut reply_comment := mydb.comments.new(
		comment: 'This is a reply to the parent comment'
		parent: parent_id
		author: 200
	) or { panic('Failed to create reply comment: ${err}') }
	
	mydb.comments.set(mut reply_comment) or { panic('Failed to save reply comment: ${err}') }
	
	// Retrieve both comments
	retrieved_parent := mydb.comments.get(parent_id) or { panic('Failed to get parent comment: ${err}') }
	retrieved_reply := mydb.comments.get(reply_comment.id) or { panic('Failed to get reply comment: ${err}') }
	
	// Verify parent comment
	assert retrieved_parent.comment == 'This is the parent comment'
	assert retrieved_parent.parent == 0
	assert retrieved_parent.author == 100
	
	// Verify reply comment
	assert retrieved_reply.comment == 'This is a reply to the parent comment'
	assert retrieved_reply.parent == parent_id
	assert retrieved_reply.author == 200
}

fn test_comment_update() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Create and save a comment
	mut comment := mydb.comments.new(
		comment: 'Original comment text'
		parent: 0
		author: 300
	) or { panic('Failed to create comment: ${err}') }
	
	mydb.comments.set(mut comment) or { panic('Failed to save comment: ${err}') }
	original_id := comment.id
	original_created_at := comment.created_at
	original_updated_at := comment.updated_at
	
	// Update the comment
	comment.comment = 'Updated comment text'
	comment.parent = 999
	comment.author = 400
	
	mydb.comments.set(mut comment) or { panic('Failed to update comment: ${err}') }
	
	// Verify ID remains the same and updated_at is set
	assert comment.id == original_id
	assert comment.created_at == original_created_at
	assert comment.updated_at >= original_updated_at
	
	// Retrieve and verify updates
	updated_comment := mydb.comments.get(comment.id) or { panic('Failed to get updated comment: ${err}') }
	assert updated_comment.comment == 'Updated comment text'
	assert updated_comment.parent == 999
	assert updated_comment.author == 400
}

fn test_comment_exist() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Test non-existent comment
	exists := mydb.comments.exist(999) or { panic('Failed to check existence: ${err}') }
	assert exists == false
	
	// Create and save a comment
	mut comment := mydb.comments.new(
		comment: 'Existence test comment'
		parent: 0
		author: 500
	) or { panic('Failed to create comment: ${err}') }
	
	mydb.comments.set(mut comment) or { panic('Failed to save comment: ${err}') }
	
	// Test existing comment
	exists_after_save := mydb.comments.exist(comment.id) or { panic('Failed to check existence: ${err}') }
	assert exists_after_save == true
}

fn test_comment_delete() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Create and save a comment
	mut comment := mydb.comments.new(
		comment: 'This comment will be deleted'
		parent: 0
		author: 600
	) or { panic('Failed to create comment: ${err}') }
	
	mydb.comments.set(mut comment) or { panic('Failed to save comment: ${err}') }
	comment_id := comment.id
	
	// Verify it exists
	exists_before := mydb.comments.exist(comment_id) or { panic('Failed to check existence: ${err}') }
	assert exists_before == true
	
	// Delete the comment
	mydb.comments.delete(comment_id) or { panic('Failed to delete comment: ${err}') }
	
	// Verify it no longer exists
	exists_after := mydb.comments.exist(comment_id) or { panic('Failed to check existence: ${err}') }
	assert exists_after == false
	
	// Verify get fails
	if _ := mydb.comments.get(comment_id) {
		panic('Should not be able to get deleted comment')
	}
}

fn test_comment_list() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Clear any existing comments by creating a fresh DB
	mydb = heromodels.new() or { panic('Failed to create fresh DB: ${err}') }
	
	// Initially should be empty
	initial_list := mydb.comments.list() or { panic('Failed to list comments: ${err}') }
	initial_count := initial_list.len
	
	// Create multiple comments
	mut comment1 := mydb.comments.new(
		comment: 'First comment'
		parent: 0
		author: 700
	) or { panic('Failed to create comment1: ${err}') }
	
	mut comment2 := mydb.comments.new(
		comment: 'Second comment'
		parent: 0
		author: 800
	) or { panic('Failed to create comment2: ${err}') }
	
	// Save both comments
	mydb.comments.set(mut comment1) or { panic('Failed to save comment1: ${err}') }
	mydb.comments.set(mut comment2) or { panic('Failed to save comment2: ${err}') }
	
	// List comments
	comment_list := mydb.comments.list() or { panic('Failed to list comments: ${err}') }
	
	// Should have 2 more comments than initially
	assert comment_list.len == initial_count + 2
	
	// Find our comments in the list
	mut found_comment1 := false
	mut found_comment2 := false
	
	for cmt in comment_list {
		if cmt.comment == 'First comment' {
			found_comment1 = true
			assert cmt.author == 700
			assert cmt.parent == 0
		}
		if cmt.comment == 'Second comment' {
			found_comment2 = true
			assert cmt.author == 800
			assert cmt.parent == 0
		}
	}
	
	assert found_comment1 == true
	assert found_comment2 == true
}

fn test_comment_edge_cases() {
	mut mydb := heromodels.new() or { panic('Failed to create DB: ${err}') }
	
	// Test empty comment
	mut empty_comment := mydb.comments.new(
		comment: ''
		parent: 0
		author: 0
	) or { panic('Failed to create empty comment: ${err}') }
	
	mydb.comments.set(mut empty_comment) or { panic('Failed to save empty comment: ${err}') }
	
	retrieved_empty := mydb.comments.get(empty_comment.id) or { panic('Failed to get empty comment: ${err}') }
	assert retrieved_empty.comment == ''
	assert retrieved_empty.parent == 0
	assert retrieved_empty.author == 0
	
	// Test very long comment
	long_text := 'This is a very long comment. '.repeat(100)
	mut long_comment := mydb.comments.new(
		comment: long_text
		parent: 12345
		author: 99999
	) or { panic('Failed to create long comment: ${err}') }
	
	mydb.comments.set(mut long_comment) or { panic('Failed to save long comment: ${err}') }
	
	retrieved_long := mydb.comments.get(long_comment.id) or { panic('Failed to get long comment: ${err}') }
	assert retrieved_long.comment == long_text
	assert retrieved_long.parent == 12345
	assert retrieved_long.author == 99999
	
	// Test comment with special characters
	special_text := 'Comment with special chars: !@#$%^&*()_+-=[]{}|;:,.<>?/~`'
	mut special_comment := mydb.comments.new(
		comment: special_text
		parent: 0
		author: 1000
	) or { panic('Failed to create special comment: ${err}') }
	
	mydb.comments.set(mut special_comment) or { panic('Failed to save special comment: ${err}') }
	
	retrieved_special := mydb.comments.get(special_comment.id) or { panic('Failed to get special comment: ${err}') }
	assert retrieved_special.comment == special_text
	assert retrieved_special.author == 1000
}
