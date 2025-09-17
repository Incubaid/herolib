#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals -no-skip-unused test

module models_ledger

import freeflowuniverse.herolib.hero.db
import freeflowuniverse.herolib.data.encoder

fn test_userkvsitem_new() {
	mut mydb := setup_test_db()!
	mut item_db := DBUserKVSItem{db: &mydb}

	mut item := item_db.new(
		name: 'Test KVS Item'
		description: 'A test KVS item for unit testing'
		kvs_id: 1
		key: 'test_key'
		value: 'test_value'
	)!

	assert item.name == 'Test KVS Item'
	assert item.description == 'A test KVS item for unit testing'
	assert item.kvs_id == 1
	assert item.key == 'test_key'
	assert item.value == 'test_value'
	assert item.timestamp > 0
	assert item.id == 0
	assert item.updated_at > 0
}

fn test_userkvsitem_encoding_decoding() {
	mut mydb := setup_test_db()!
	mut item_db := DBUserKVSItem{db: &mydb}

	mut original_item := item_db.new(
		name: 'Encoding Test Item'
		description: 'Testing encoding and decoding'
		kvs_id: 999
		key: 'encoding_key'
		value: 'encoding_value_with_special_chars_!@#$%^&*()'
	)!

	// Test encoding
	mut encoder_obj := encoder.new()
	original_item.dump(mut encoder_obj)!
	encoded_data := encoder_obj.bytes()

	// Test decoding
	mut decoder_obj := encoder.new_decoder(encoded_data)
	mut decoded_item := UserKVSItem{}
	item_db.load(mut decoded_item, mut decoder_obj)!

	// Verify all fields match
	assert decoded_item.kvs_id == original_item.kvs_id
	assert decoded_item.key == original_item.key
	assert decoded_item.value == original_item.value
	assert decoded_item.timestamp == original_item.timestamp
}

fn test_userkvsitem_crud_operations() {
	mut mydb := setup_test_db()!
	mut item_db := DBUserKVSItem{db: &mydb}

	// Create and save
	mut item := item_db.new(
		name: 'CRUD Test Item'
		description: 'Testing CRUD operations'
		kvs_id: 5
		key: 'crud_key'
		value: 'crud_value'
	)!

	item = item_db.set(item)!
	assert item.id > 0
	item_id := item.id

	// Get
	retrieved := item_db.get(item_id)!
	assert retrieved.kvs_id == 5
	assert retrieved.key == 'crud_key'
	assert retrieved.value == 'crud_value'

	// Update
	item.key = 'updated_key'
	item.value = 'updated_value'
	item = item_db.set(item)!

	updated := item_db.get(item_id)!
	assert updated.key == 'updated_key'
	assert updated.value == 'updated_value'

	// Exist
	exists := item_db.exist(item_id)!
	assert exists == true

	// Delete
	item_db.delete(item_id)!
	exists_after := item_db.exist(item_id)!
	assert exists_after == false
}

fn test_userkvsitem_list() {
	mut mydb := setup_test_db()!
	mut item_db := DBUserKVSItem{db: &mydb}

	initial_list := item_db.list()!
	initial_count := initial_list.len

	// Create multiple items
	mut item1 := item_db.new(
		name: 'Item 1'
		description: 'First item'
		kvs_id: 1
		key: 'key1'
		value: 'value1'
	)!

	mut item2 := item_db.new(
		name: 'Item 2'
		description: 'Second item'
		kvs_id: 2
		key: 'key2'
		value: 'value2'
	)!

	item1 = item_db.set(item1)!
	item2 = item_db.set(item2)!

	item_list := item_db.list()!
	assert item_list.len == initial_count + 2

	mut found1 := false
	mut found2 := false
	for item in item_list {
		if item.key == 'key1' {
			found1 = true
			assert item.kvs_id == 1
			assert item.value == 'value1'
		}
		if item.key == 'key2' {
			found2 = true
			assert item.kvs_id == 2
			assert item.value == 'value2'
		}
	}
	assert found1 && found2
}

fn test_userkvsitem_edge_cases() {
	mut mydb := setup_test_db()!
	mut item_db := DBUserKVSItem{db: &mydb}

	// Test empty strings
	mut minimal_item := item_db.new(
		name: ''
		description: ''
		kvs_id: 0
		key: ''
		value: ''
	)!

	minimal_item = item_db.set(minimal_item)!
	retrieved := item_db.get(minimal_item.id)!

	assert retrieved.name == ''
	assert retrieved.description == ''
	assert retrieved.kvs_id == 0
	assert retrieved.key == ''
	assert retrieved.value == ''

	// Test large strings
	large_key := 'large_key_' + 'K'.repeat(1000)
	large_value := 'large_value_' + 'V'.repeat(10000)

	mut large_item := item_db.new(
		name: 'Large Item'
		description: 'Testing with large strings'
		kvs_id: 999999
		key: large_key
		value: large_value
	)!

	large_item = item_db.set(large_item)!
	retrieved_large := item_db.get(large_item.id)!

	assert retrieved_large.key == large_key
	assert retrieved_large.value == large_value
	assert retrieved_large.kvs_id == 999999

	// Test special characters
	special_key := 'key_with_unicode_🔑'
	special_value := 'value_with_unicode_💎_and_newlines\n\r\t'

	mut special_item := item_db.new(
		name: 'Special Characters Item'
		description: 'Testing special characters'
		kvs_id: 1
		key: special_key
		value: special_value
	)!

	special_item = item_db.set(special_item)!
	retrieved_special := item_db.get(special_item.id)!

	assert retrieved_special.key == special_key
	assert retrieved_special.value == special_value
}