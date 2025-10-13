module dedupestor

fn test_reference_bytes_conversion() {
	ref := Reference{
		owner: 12345
		id:    67890
	}

	bytes := ref.to_bytes()
	recovered := bytes_to_reference(bytes)

	assert ref.owner == recovered.owner
	assert ref.id == recovered.id
}

fn test_metadata_bytes_conversion() {
	mut metadata := Metadata{
		id:         42
		references: []Reference{}
	}

	ref1 := Reference{
		owner: 1
		id:    100
	}
	ref2 := Reference{
		owner: 2
		id:    200
	}

	metadata = metadata.add_reference(ref1)!
	metadata = metadata.add_reference(ref2)!

	bytes := metadata.to_bytes()
	recovered := bytes_to_metadata(bytes)

	assert metadata.id == recovered.id
	assert metadata.references.len == recovered.references.len
	assert metadata.references[0].owner == recovered.references[0].owner
	assert metadata.references[0].id == recovered.references[0].id
	assert metadata.references[1].owner == recovered.references[1].owner
	assert metadata.references[1].id == recovered.references[1].id
}

fn test_add_reference() {
	mut metadata := Metadata{
		id:         1
		references: []Reference{}
	}

	ref1 := Reference{
		owner: 1
		id:    100
	}
	ref2 := Reference{
		owner: 2
		id:    200
	}

	// Add first reference
	metadata = metadata.add_reference(ref1)!
	assert metadata.references.len == 1
	assert metadata.references[0].owner == ref1.owner
	assert metadata.references[0].id == ref1.id

	// Add second reference
	metadata = metadata.add_reference(ref2)!
	assert metadata.references.len == 2
	assert metadata.references[1].owner == ref2.owner
	assert metadata.references[1].id == ref2.id

	// Try adding duplicate reference
	metadata = metadata.add_reference(ref1)!
	assert metadata.references.len == 2 // Length shouldn't change
}

fn test_remove_reference() {
	mut metadata := Metadata{
		id:         1
		references: []Reference{}
	}

	ref1 := Reference{
		owner: 1
		id:    100
	}
	ref2 := Reference{
		owner: 2
		id:    200
	}

	metadata = metadata.add_reference(ref1)!
	metadata = metadata.add_reference(ref2)!

	// Remove first reference
	metadata = metadata.remove_reference(ref1)!
	assert metadata.references.len == 1
	assert metadata.references[0].owner == ref2.owner
	assert metadata.references[0].id == ref2.id

	// Remove non-existent reference
	metadata = metadata.remove_reference(Reference{ owner: 999, id: 999 })!
	assert metadata.references.len == 1 // Length shouldn't change

	// Remove last reference
	metadata = metadata.remove_reference(ref2)!
	assert metadata.references.len == 0
}

fn test_empty_metadata_bytes() {
	empty := bytes_to_metadata([]u8{})
	assert empty.id == 0
	assert empty.references.len == 0
}

fn test_u32_bytes_conversion() {
	n := u32(0x12345678)
	bytes := u32_to_bytes(n)
	recovered := bytes_to_u32(bytes)
	assert n == recovered
}
