# HeroFS REST API Server

A comprehensive REST API server for the HeroFS distributed filesystem, built with V and VEB framework.

## Features

- **Complete CRUD Operations** for all HeroFS entities (Filesystems, Directories, Files, Blobs, Symlinks)
- **Advanced Filesystem Tools** (find, copy, move, remove, import/export)
- **CORS Support** for frontend integration
- **JSON Request/Response** with consistent error handling
- **RESTful Design** following standard HTTP conventions
- **Production Ready** with proper error handling and validation

## Quick Start

```v
import incubaid.herolib.hero.herofs_server

// Create and start server
mut server := herofs_server.new(
    port: 8080
    host: 'localhost'
    cors_enabled: true
    allowed_origins: ['*']
)!

server.start()!
```

## API Endpoints

### Health & Info

- `GET /health` - Health check
- `GET /api` - API information and available endpoints

### Filesystems (`/api/fs`)

- `GET /api/fs` - List all filesystems
- `GET /api/fs/:id` - Get filesystem by ID
- `POST /api/fs` - Create new filesystem
- `PUT /api/fs/:id` - Update filesystem
- `DELETE /api/fs/:id` - Delete filesystem
- `GET /api/fs/:id/exists` - Check if filesystem exists
- `POST /api/fs/:id/usage/increase` - Increase usage counter
- `POST /api/fs/:id/usage/decrease` - Decrease usage counter
- `POST /api/fs/:id/quota/check` - Check quota availability

### Directories (`/api/dirs`)

- `GET /api/dirs` - List all directories
- `GET /api/dirs/:id` - Get directory by ID
- `POST /api/dirs` - Create new directory
- `PUT /api/dirs/:id` - Update directory
- `DELETE /api/dirs/:id` - Delete directory
- `POST /api/dirs/create-path` - Create directory path
- `GET /api/dirs/:id/has-children` - Check if directory has children
- `GET /api/dirs/:id/children` - Get directory children

### Files (`/api/files`)

- `GET /api/files` - List all files
- `GET /api/files/:id` - Get file by ID
- `POST /api/files` - Create new file
- `PUT /api/files/:id` - Update file
- `DELETE /api/files/:id` - Delete file
- `POST /api/files/:id/add-to-directory` - Add file to directory
- `POST /api/files/:id/remove-from-directory` - Remove file from directory
- `POST /api/files/:id/metadata` - Update file metadata
- `POST /api/files/:id/accessed` - Update accessed timestamp
- `GET /api/files/by-filesystem/:fs_id` - List files by filesystem

### Blobs (`/api/blobs`)

- `GET /api/blobs` - List all blobs
- `GET /api/blobs/:id` - Get blob by ID
- `POST /api/blobs` - Create new blob
- `PUT /api/blobs/:id` - Update blob
- `DELETE /api/blobs/:id` - Delete blob
- `GET /api/blobs/:id/content` - Get blob raw content
- `GET /api/blobs/:id/verify` - Verify blob integrity

### Symlinks (`/api/symlinks`)

- `GET /api/symlinks` - List all symlinks
- `GET /api/symlinks/:id` - Get symlink by ID
- `POST /api/symlinks` - Create new symlink
- `PUT /api/symlinks/:id` - Update symlink
- `DELETE /api/symlinks/:id` - Delete symlink
- `GET /api/symlinks/:id/is-broken` - Check if symlink is broken

### Blob Membership (`/api/blob-membership`)

- `GET /api/blob-membership` - List all blob memberships
- `GET /api/blob-membership/:id` - Get blob membership by ID
- `POST /api/blob-membership` - Create new blob membership
- `DELETE /api/blob-membership/:id` - Delete blob membership

### Filesystem Tools (`/api/tools`)

- `POST /api/tools/find` - Find files and directories
- `POST /api/tools/copy` - Copy files or directories
- `POST /api/tools/move` - Move files or directories
- `POST /api/tools/remove` - Remove files or directories
- `POST /api/tools/list` - List directory contents
- `POST /api/tools/import/file` - Import file from real filesystem
- `POST /api/tools/import/directory` - Import directory from real filesystem
- `POST /api/tools/export/file` - Export file to real filesystem
- `POST /api/tools/export/directory` - Export directory to real filesystem
- `POST /api/tools/content/:fs_id` - Get file content as text

## Request/Response Format

### Standard Response Structure

```json
{
  "success": true,
  "data": { ... },
  "message": "Operation completed successfully",
  "error": ""
}
```

### Error Response Structure

```json
{
  "success": false,
  "error": "Error description",
  "message": "User-friendly error message"
}
```

## Example Usage

### Create a Filesystem

```bash
curl -X POST http://localhost:8080/api/fs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my_filesystem",
    "description": "My test filesystem",
    "quota_bytes": 1073741824
  }'
```

### Create a Directory

```bash
curl -X POST http://localhost:8080/api/dirs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "documents",
    "fs_id": 1,
    "parent_id": 0,
    "description": "Documents directory"
  }'
```

### Find Files

```bash
curl -X POST http://localhost:8080/api/tools/find \
  -H "Content-Type: application/json" \
  -d '{
    "fs_id": 1,
    "pattern": "*.txt",
    "recursive": true
  }'
```

### Import File

```bash
curl -X POST http://localhost:8080/api/tools/import/file \
  -H "Content-Type: application/json" \
  -d '{
    "fs_id": 1,
    "real_path": "/path/to/local/file.txt",
    "vfs_path": "/imported/file.txt",
    "overwrite": false
  }'
```

## HTTP Status Codes

- `200 OK` - Successful operation
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request format or parameters
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

## CORS Support

The server supports CORS for frontend integration. Configure allowed origins when creating the server:

```v
mut server := herofs_server.new(
    cors_enabled: true
    allowed_origins: ['http://localhost:3000', 'https://myapp.com']
)!
```

## Error Handling

The API provides comprehensive error handling with:

- Input validation for all parameters
- Proper HTTP status codes
- Detailed error messages
- Consistent error response format

## Integration with HeroFS

The server integrates seamlessly with the HeroFS module, providing:

- Full access to all HeroFS functionality
- Proper factory pattern usage
- Data integrity through BLAKE3 hashing
- Efficient Redis-based storage
- Complete filesystem operations

## Production Deployment

For production use:

1. Configure appropriate CORS origins
2. Set up proper logging
3. Configure Redis connection
4. Set appropriate quotas and limits
5. Monitor server performance

The server is designed to be production-ready with proper error handling, validation, and performance considerations.
