module vfs_db

import os
import time
import incubaid.herolib.vfs

fn test_directory_encoder_decoder() ! {
	println('Testing encoding/decoding directories...')

	current_time := time.now().unix()
	dir := Directory{
		metadata:  vfs.Metadata{
			id:          u32(current_time)
			name:        'root'
			file_type:   .directory
			created_at:  current_time
			modified_at: current_time
			accessed_at: current_time
			mode:        0o755
			owner:       'user'
			group:       'user'
		}
		children:  [u32(1), u32(2)]
		parent_id: 0
	}

	encoded := dir.encode()

	mut decoded := decode_directory(encoded) or {
		return error('Failed to decode directory: ${err}')
	}

	assert decoded.metadata.id == dir.metadata.id
	assert decoded.metadata.name == dir.metadata.name
	assert decoded.metadata.file_type == dir.metadata.file_type
	assert decoded.metadata.created_at == dir.metadata.created_at
	assert decoded.metadata.modified_at == dir.metadata.modified_at
	assert decoded.metadata.accessed_at == dir.metadata.accessed_at
	assert decoded.metadata.mode == dir.metadata.mode
	assert decoded.metadata.owner == dir.metadata.owner
	assert decoded.metadata.group == dir.metadata.group
	assert decoded.children == dir.children
	assert decoded.parent_id == dir.parent_id

	println('Test completed successfully!')
}

fn test_file_encoder_decoder() ! {
	println('Testing encoding/decoding files...')

	current_time := time.utc().unix()
	file := File{
		metadata: vfs.Metadata{
			id:          u32(current_time)
			name:        'test.txt'
			file_type:   .file
			size:        13 // Size of 'Hello, world!'
			created_at:  current_time
			modified_at: current_time
			accessed_at: current_time
			mode:        0o644
			owner:       'user'
			group:       'user'
		}
		// data:      'Hello, world!'
		parent_id: 0
		chunk_ids: [u32(12), u32(27)]
	}

	encoded := file.encode()

	decoded := decode_file_metadata(encoded) or { return error('Failed to decode file: ${err}') }

	assert decoded.metadata.id == file.metadata.id
	assert decoded.metadata.name == file.metadata.name
	assert decoded.metadata.file_type == file.metadata.file_type
	assert decoded.metadata.created_at == file.metadata.created_at
	assert decoded.metadata.modified_at == file.metadata.modified_at
	assert decoded.metadata.accessed_at == file.metadata.accessed_at
	assert decoded.metadata.mode == file.metadata.mode
	assert decoded.metadata.owner == file.metadata.owner
	assert decoded.metadata.group == file.metadata.group
	assert decoded.parent_id == file.parent_id
	assert decoded.chunk_ids == [u32(12), u32(27)]

	println('Test completed successfully!')
}

fn test_symlink_encoder_decoder() ! {
	println('Testing encoding/decoding symlinks...')

	current_time := time.now().unix()
	symlink := Symlink{
		metadata:  vfs.Metadata{
			id:          u32(current_time)
			name:        'test.txt'
			file_type:   .symlink
			created_at:  current_time
			modified_at: current_time
			accessed_at: current_time
			mode:        0o644
			owner:       'user'
			group:       'user'
		}
		target:    'test.txt'
		parent_id: 0
	}

	encoded := symlink.encode()

	mut decoded := decode_symlink(encoded) or { return error('Failed to decode symlink: ${err}') }

	assert decoded.metadata.id == symlink.metadata.id
	assert decoded.metadata.name == symlink.metadata.name
	assert decoded.metadata.file_type == symlink.metadata.file_type
	assert decoded.metadata.created_at == symlink.metadata.created_at
	assert decoded.metadata.modified_at == symlink.metadata.modified_at
	assert decoded.metadata.accessed_at == symlink.metadata.accessed_at
	assert decoded.metadata.mode == symlink.metadata.mode
	assert decoded.metadata.owner == symlink.metadata.owner
	assert decoded.metadata.group == symlink.metadata.group
	assert decoded.target == symlink.target
	assert decoded.parent_id == symlink.parent_id

	println('Test completed successfully!')
}
