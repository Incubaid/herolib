# Contacts VFS Module

This module contains the Virtual File System (VFS) implementation for the Contacts component of the MCC (Mail, Contacts, Calendar) system, built in the V programming language. The Contacts VFS provides a read-only interface to browse and access contact data in a file system-like structure, which can be mounted and accessed via protocols like WebDAV.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Usage](#usage)
- [Testing](#testing)
- [Extending the Implementation](#extending-the-implementation)

## Overview

The Contacts VFS implementation provides a read-only virtual file system interface to the contacts backend service. It organizes contact data hierarchically, with contact groups as directories and individual contacts as JSON files. Contacts can be browsed by name or email, making it easy to integrate with tools that support file system protocols such as WebDAV.

## Features

- **Consistent Interface**: Adheres to the `vfs.VFS` interface defined in `/lib/vfs/interface.v`, ensuring compatibility with other MCC VFS implementations.
- **Read-Only Access**: Provides read-only access to contact data, with plans for future write support.
- **Structured Data Access**:
  - Organizes contact groups as directories.
  - Represents individual contacts as JSON files.
  - Allows browsing by name (`by_name`) and email (`by_email`).
- **Comprehensive Testing**: Includes unit tests to verify functionality.
- **Error Handling**: Gracefully handles errors for invalid paths, non-existent entries, and unsupported operations.

## Usage

The Contacts VFS organizes contact groups as directories, with contacts as JSON files, browsable by name and email.

**Example Structure**:

```
/personal/
├── by_name/
│   └── john_doe.json
├── by_email/
│   └── john_doe_example_com.json
/work/
├── by_name/
│   └── jane_smith.json
├── by_email/
│   └── jane_smith_example_com.json
```

**Usage Example**:

```v
import incubaid.herolib.vfs
import vfs_contacts
import incubaid.herolib.circles.dbs.core

fn main() ! {
    // Setup mock database
    mut contacts_db := core.new_mock_contacts_db()
    contact1 := contacts.Contact{
  id:          1
        first_name: 'John'
        last_name: 'Doe'
        email: 'john.doe@example.com'
        group: 'personal'
        created_at: 1698777600
        modified_at: 1698777600
 }

    contact2 := contacts.Contact{
  id:          2
        first_name: 'Said'
        last_name: 'Moaawad'
        email: 'said.moaawad@example.com'
        group: 'personal'
        created_at: 1698777600
        modified_at: 1698777600
 }

 // Add contacts to the database
 contacts_db.set(contact1) or { panic(err) }
 contacts_db.set(contact2) or { panic(err) }

 // Create VFS instance
 mut contacts_vfs := new(&contacts_db) or { panic(err) }

    // List groups at root
    groups := contacts_vfs.dir_list('')!
    for group in groups {
        println('Group: ${group.metadata.name}')
    }

    // List contacts in personal group by name
    contacts_by_name := contacts_vfs.dir_list('personal/by_name')!
    for contact in contacts_by_name {
        println('Contact: ${contact.metadata.name}')
    }

    // Read a contact
    contact_data := contacts_vfs.file_read('personal/by_name/john_doe.json')!
    println('Contact content: ${contact_data.bytestr()}')

    // Check if a contact exists
    exists := contacts_vfs.exists('personal/by_email/john_doe_example_com.json')
    println('Contact exists: ${exists}')
}
```

### Key Methods

- **`dir_list(path string) ![]vfs.FSEntry`**: Lists the contents of a directory (e.g., groups, subdirectories, or contact files).
- **`file_read(path string) ![]u8`**: Reads the JSON content of a contact file.
- **`exists(path string) bool`**: Checks if a path (group, subdirectory, or contact file) exists.
- **`get(path string) !vfs.FSEntry`**: Retrieves metadata for a path.

### Notes

- All paths are case-sensitive and use forward slashes (`/`).
- Contact file names are normalized using `texttools.name_fix` to ensure valid file system names (e.g., replacing special characters).

## Testing

The Contacts VFS implementation includes comprehensive unit tests in the `vfs_implementation_test.v` file. To run the tests:

1. **Navigate to the Module Directory**:

   ```bash
   cd lib/vfs/vfs_contacts/
   ```

2. **Run Tests**:

   ```bash
   v test .
   ```

The tests cover:

- Listing groups, subdirectories, and contact files
- Reading contact file contents
- Existence checks
- Error handling for invalid paths and unsupported operations
