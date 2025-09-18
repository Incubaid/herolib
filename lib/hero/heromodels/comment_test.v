module heromodels

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.ourtime

fn test_comment_new() ! {
	// Initialize DBComments for testing
	mut mydb := db.new_test()!
	mut db_comments := DBComments{
		db: &mydb
	}

	// Test creating a new comment
	mut args := CommentArg{
		subject: 'Test Subject'
		comment: 'This is a test comment.'
		parent:  0
		author:  1
		to:      [u32(2), u32(3)]
		cc:      [u32(4), u32(5)]
	}

	comment := db_comments.new(args)!

	assert comment.subject == 'Test Subject'
	assert comment.comment == 'This is a test comment.'
	assert comment.parent == 0
	assert comment.author == 1
	assert comment.to.len == 2
	assert comment.to[0] == 2
	assert comment.to[1] == 3
	assert comment.cc.len == 2
	assert comment.cc[0] == 4
	assert comment.cc[1] == 5
	assert comment.updated_at > 0

	println('✓ Comment new test passed!')
}

fn test_comment_crud_operations() ! {
	// Initialize DBComments for testing
	mut mydb := db.new_test()!
	mut db_comments := DBComments{
		db: &mydb
	}

	// Create a new comment
	mut args := CommentArg{
		subject: 'CRUD Test Subject'
		comment: 'This is a test comment for CRUD operations.'
		parent:  0
		author:  1
		to:      [u32(2), u32(3)]
		cc:      [u32(4), u32(5)]
	}

	mut comment := db_comments.new(args)!

	// Test set operation
	comment = db_comments.set(comment)!
	original_id := comment.id

	// Test get operation
	retrieved_comment := db_comments.get(original_id)!
	assert retrieved_comment.subject == 'CRUD Test Subject'
	assert retrieved_comment.comment == 'This is a test comment for CRUD operations.'
	assert retrieved_comment.parent == 0
	assert retrieved_comment.author == 1
	assert retrieved_comment.id == original_id
	assert retrieved_comment.to.len == 2
	assert retrieved_comment.to[0] == 2
	assert retrieved_comment.to[1] == 3
	assert retrieved_comment.cc.len == 2
	assert retrieved_comment.cc[0] == 4
	assert retrieved_comment.cc[1] == 5

	// Test exist operation
	exists := db_comments.exist(original_id)!
	assert exists == true

	// Test update
	mut updated_args := CommentArg{
		subject: 'Updated Test Subject'
		comment: 'This is an updated test comment.'
		parent:  10
		author:  2
		to:      [u32(6)]
		cc:      [u32(7), u32(8), u32(9)]
	}

	mut updated_comment := db_comments.new(updated_args)!
	updated_comment.id = original_id
	updated_comment = db_comments.set(updated_comment)!

	// Verify update
	final_comment := db_comments.get(original_id)!
	assert final_comment.subject == 'Updated Test Subject'
	assert final_comment.comment == 'This is an updated test comment.'
	assert final_comment.parent == 10
	assert final_comment.author == 2
	assert final_comment.to.len == 1
	assert final_comment.to[0] == 6
	assert final_comment.cc.len == 3
	assert final_comment.cc[0] == 7
	assert final_comment.cc[1] == 8
	assert final_comment.cc[2] == 9

	// Test delete operation
	db_comments.delete(original_id)!

	// Verify deletion
	exists_after_delete := db_comments.exist(original_id)!
	assert exists_after_delete == false

	println('✓ Comment CRUD operations test passed!')
}

fn test_comment_encoding_decoding() ! {
	// Initialize DBComments for testing
	mut mydb := db.new_test()!
	mut db_comments := DBComments{
		db: &mydb
	}

	// Create a new comment with all fields populated
	mut args := CommentArg{
		subject: 'Encoding Test Subject'
		comment: 'This is a test comment for encoding/decoding.'
		parent:  5
		author:  10
		to:      [u32(20), u32(30), u32(40)]
		cc:      [u32(50), u32(60)]
	}

	mut comment := db_comments.new(args)!

	// Save the comment
	comment = db_comments.set(comment)!
	comment_id := comment.id

	// Retrieve and verify all fields were properly encoded/decoded
	retrieved_comment := db_comments.get(comment_id)!

	assert retrieved_comment.subject == 'Encoding Test Subject'
	assert retrieved_comment.comment == 'This is a test comment for encoding/decoding.'
	assert retrieved_comment.parent == 5
	assert retrieved_comment.author == 10
	assert retrieved_comment.to.len == 3
	assert retrieved_comment.to[0] == 20
	assert retrieved_comment.to[1] == 30
	assert retrieved_comment.to[2] == 40
	assert retrieved_comment.cc.len == 2
	assert retrieved_comment.cc[0] == 50
	assert retrieved_comment.cc[1] == 60

	println('✓ Comment encoding/decoding test passed!')
}

fn test_comment_type_name() ! {
	// Initialize DBComments for testing
	mut mydb := db.new_test()!
	mut db_comments := DBComments{
		db: &mydb
	}

	// Create a new comment
	mut args := CommentArg{
		subject: 'Type Name Test Subject'
		comment: 'This is a test comment for type name.'
		parent:  0
		author:  1
		to:      []u32{}
		cc:      []u32{}
	}

	comment := db_comments.new(args)!

	// Test type_name method
	type_name := comment.type_name()
	assert type_name == 'comments'

	println('✓ Comment type_name test passed!')
}

fn test_comment_description() ! {
	// Initialize DBComments for testing
	mut mydb := db.new_test()!
	mut db_comments := DBComments{
		db: &mydb
	}

	// Create a new comment
	mut args := CommentArg{
		subject: 'Description Test Subject'
		comment: 'This is a test comment for description method.'
		parent:  0
		author:  1
		to:      []u32{}
		cc:      []u32{}
	}

	comment := db_comments.new(args)!

	// Test description method for each methodname
	assert comment.description('set') == 'Create or update a comment. Returns the ID of the comment.'
	assert comment.description('get') == 'Retrieve a comment by ID. Returns the comment object.'
	assert comment.description('delete') == 'Delete a comment by ID. Returns true if successful.'
	assert comment.description('exist') == 'Check if a comment exists by ID. Returns true or false.'
	assert comment.description('list') == 'List all comments. Returns an array of comment objects.'
	assert comment.description('unknown') == 'This is generic method for the root object, TODO fill in, ...'

	println('✓ Comment description test passed!')
}

fn test_comment_example() ! {
	// Initialize DBComments for testing
	mut mydb := db.new_test()!
	mut db_comments := DBComments{
		db: &mydb
	}

	// Create a new comment
	mut args := CommentArg{
		subject: 'Example Test Subject'
		comment: 'This is a test comment for example method.'
		parent:  0
		author:  1
		to:      []u32{}
		cc:      []u32{}
	}

	comment := db_comments.new(args)!

	// Test example method for each methodname
	set_call, set_result := comment.example('set')
	assert set_call == '{"comment": {"comment": "This is a test comment.", "parent": 0, "author": 1}}'
	assert set_result == '1'

	get_call, get_result := comment.example('get')
	assert get_call == '{"id": 1}'
	assert get_result == '{"comment": "This is a test comment.", "parent": 0, "author": 1}'

	delete_call, delete_result := comment.example('delete')
	assert delete_call == '{"id": 1}'
	assert delete_result == 'true'

	exist_call, exist_result := comment.example('exist')
	assert exist_call == '{"id": 1}'
	assert exist_result == 'true'

	list_call, list_result := comment.example('list')
	assert list_call == '{}'
	assert list_result == '[{"comment": "This is a test comment.", "parent": 0, "author": 1}]'

	unknown_call, unknown_result := comment.example('unknown')
	assert unknown_call == '{}'
	assert unknown_result == '{}'

	println('✓ Comment example test passed!')
}
