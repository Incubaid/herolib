# HeroFS TypeScript Client

A comprehensive TypeScript client for the HeroFS distributed filesystem REST API. Provides type-safe access to **all 61 endpoints** with proper error handling, CORS support, and extensive documentation.

## ✅ **100% API Coverage Achieved**

This client provides complete coverage of the HeroFS REST API with **61 endpoints** across all categories:

- **Health & Info**: 2 endpoints
- **Filesystems**: 9 endpoints (including get-by-name)
- **Directories**: 9 endpoints (including by-filesystem, children)
- **Files**: 12 endpoints (including by-directory, by-mime-type, by-path)
- **Blobs**: 8 endpoints (including by-hash, exists-by-hash, verify)
- **Symlinks**: 6 endpoints (including by-filesystem, is-broken)
- **Blob Membership**: 6 endpoints (including add/remove filesystem)
- **Tools**: 10 endpoints (find, copy, move, import/export, etc.)

## Features

- **Complete API Coverage** - All 61 HeroFS REST endpoints (100% coverage)
- **Type Safety** - Full TypeScript support with detailed interfaces
- **Error Handling** - Custom error classes with status codes and user messages
- **CORS Support** - Cross-origin requests for frontend integration
- **Promise-based** - Modern async/await patterns
- **Retry Logic** - Built-in retry utilities for resilient operations
- **Zero Dependencies** - Only uses standard fetch API
- **Tree Shakeable** - Import only what you need
- **Comprehensive Testing** - Complete test suite covering all endpoints

## Installation

```bash
npm install @herolib/herofs-client
# or
yarn add @herolib/herofs-client
# or
pnpm add @herolib/herofs-client
# or (recommended for examples)
bun add @herolib/herofs-client
```

## 🚀 **Example Scripts**

Get started quickly with our comprehensive example scripts in the `scripts/` directory:

```bash
# Install dependencies
bun install

# Run the complete file creation workflow
bun run example:write

# See all available examples
bun run examples
```

**Available Examples:**

- **`create-and-write-file.ts`** - Complete workflow: filesystem → directory → blob → file
- **`read-and-list-files.ts`** *(Coming Soon)* - Read content and list files
- **`search-and-filter.ts`** *(Coming Soon)* - Search and filter operations
- **`import-export-operations.ts`** *(Coming Soon)* - Bulk import/export

👉 **[View Example Scripts →](./scripts/README.md)**

## Quick Start

```typescript
import { HeroFSClient, MimeType, isHeroFSError } from '@herolib/herofs-client';

// Create client instance
const client = new HeroFSClient({
  baseUrl: 'http://localhost:8080',
  timeout: 30000
});

// Check server health
const health = await client.healthCheck();
console.log('Server status:', health.data);

// Create a filesystem
const filesystem = await client.createFilesystem({
  name: 'my_project',
  description: 'My project filesystem',
  quota_bytes: 1073741824 // 1GB
});

// Create a directory
const directory = await client.createDirectory({
  name: 'documents',
  fs_id: filesystem.data.id,
  parent_id: 0,
  description: 'Documents folder'
});

// Create a file with content
const content = new TextEncoder().encode('Hello, HeroFS!');
const blob = await client.createBlob({
  data: Array.from(content),
  mime_type: 'text/plain'
});

const file = await client.createFile({
  name: 'hello.txt',
  fs_id: filesystem.data.id,
  directories: [directory.data.id],
  blobs: [blob.data.id],
  mime_type: MimeType.TEXT
});

console.log('Created file:', file.data);
```

## New Endpoints Added

This version includes **13 new endpoints** to achieve 100% API coverage:

### **Filesystem Endpoints**

- `getFilesystemByName(name)` - Get filesystem by name

### **Directory Endpoints**

- `listDirectoriesByFilesystem(fsId)` - List directories in a filesystem
- `getDirectoryChildren(id)` - Get child directories (already existed)

### **File Endpoints**

- `listFilesByDirectory(dirId)` - List files in a directory
- `listFilesByMimeType(mimeType)` - List files by MIME type
- `getFileByPath(dirId, name)` - Get file by directory and name

### **Blob Endpoints**

- `verifyBlobIntegrity(id)` - Verify blob data integrity
- `getBlobByHash(hash)` - Get blob by content hash
- `blobExistsByHash(hash)` - Check if blob exists by hash

### **Symlink Endpoints**

- `listSymlinksByFilesystem(fsId)` - List symlinks in a filesystem
- `checkSymlinkBroken(id)` - Check if symlink target exists

### **Blob Membership Endpoints**

- `listBlobMemberships()` - List all blob memberships
- `getBlobMembership(hash)` - Get blob membership by hash
- `createBlobMembership(data)` - Create new blob membership
- `deleteBlobMembership(hash)` - Delete blob membership
- `addFilesystemToBlobMembership(hash, fsId)` - Add filesystem to membership
- `removeFilesystemFromBlobMembership(hash, fsId)` - Remove filesystem from membership

## API Reference

### Client Configuration

```typescript
interface HeroFSClientConfig {
  baseUrl?: string;        // Default: 'http://localhost:8080'
  timeout?: number;        // Default: 30000ms
  headers?: Record<string, string>;
  corsEnabled?: boolean;
}
```

### Core Endpoints

#### Health & API Info

- `healthCheck()` - Check server health
- `getAPIInfo()` - Get API information and endpoints

#### Filesystems

- `listFilesystems()` - List all filesystems
- `getFilesystem(id)` - Get filesystem by ID
- `createFilesystem(data)` - Create new filesystem
- `updateFilesystem(id, data)` - Update filesystem
- `deleteFilesystem(id)` - Delete filesystem
- `filesystemExists(id)` - Check if filesystem exists
- `increaseFilesystemUsage(id, bytes)` - Increase usage counter
- `decreaseFilesystemUsage(id, bytes)` - Decrease usage counter
- `checkFilesystemQuota(id, bytes)` - Check quota availability

#### Directories

- `listDirectories()` - List all directories
- `getDirectory(id)` - Get directory by ID
- `createDirectory(data)` - Create new directory
- `updateDirectory(id, data)` - Update directory
- `deleteDirectory(id)` - Delete directory
- `createDirectoryPath(data)` - Create directory path
- `directoryHasChildren(id)` - Check if directory has children
- `getDirectoryChildren(id)` - Get directory children

#### Files

- `listFiles()` - List all files
- `getFile(id)` - Get file by ID
- `createFile(data)` - Create new file
- `updateFile(id, data)` - Update file
- `deleteFile(id)` - Delete file
- `addFileToDirectory(id, dirId)` - Add file to directory
- `removeFileFromDirectory(id, dirId)` - Remove file from directory
- `updateFileMetadata(id, key, value)` - Update file metadata
- `updateFileAccessed(id)` - Update accessed timestamp
- `listFilesByFilesystem(fsId)` - List files by filesystem

#### Blobs

- `listBlobs()` - List all blobs
- `getBlob(id)` - Get blob by ID
- `createBlob(data)` - Create new blob
- `updateBlob(id, data)` - Update blob
- `deleteBlob(id)` - Delete blob
- `getBlobContent(id)` - Get blob content

#### Symlinks

- `listSymlinks()` - List all symlinks
- `getSymlink(id)` - Get symlink by ID
- `createSymlink(data)` - Create new symlink
- `updateSymlink(id, data)` - Update symlink
- `deleteSymlink(id)` - Delete symlink

#### Tools

- `toolsList(data)` - List directory contents
- `toolsFind(data)` - Find files by pattern
- `toolsCopy(data)` - Copy file or directory
- `toolsMove(data)` - Move file or directory
- `toolsRemove(data)` - Remove file or directory
- `toolsImportFile(data)` - Import file from real filesystem
- `toolsImportDirectory(data)` - Import directory from real filesystem
- `toolsExportFile(data)` - Export file to real filesystem
- `toolsExportDirectory(data)` - Export directory to real filesystem
- `toolsContent(fsId, data)` - Get file content by path

## Error Handling

The client provides a custom `HeroFSError` class with helpful methods:

```typescript
import { HeroFSError, isHeroFSError } from '@herolib/herofs-client';

try {
  await client.getFilesystem(999);
} catch (error) {
  if (isHeroFSError(error)) {
    console.log('Error message:', error.userMessage);
    console.log('Status code:', error.statusCode);
    
    if (error.isClientError()) {
      console.log('Client error (4xx)');
    } else if (error.isServerError()) {
      console.log('Server error (5xx)');
    } else if (error.isNetworkError()) {
      console.log('Network error');
    } else if (error.isTimeoutError()) {
      console.log('Timeout error');
    }
  }
}
```

## Retry Logic

Built-in retry utility for resilient operations:

```typescript
import { withRetry } from '@herolib/herofs-client';

const result = await withRetry(
  () => client.createFilesystem({ name: 'test' }),
  3,    // max retries
  1000  // base delay in ms
);
```

## Utility Functions

```typescript
import { 
  textToBytes, 
  bytesToText, 
  formatFileSize, 
  validateQuota,
  getQuotaUsagePercentage 
} from '@herolib/herofs-client';

// Convert text to bytes for blob operations
const bytes = textToBytes('Hello, World!');

// Convert bytes back to text
const text = bytesToText(bytes);

// Format file sizes
const size = formatFileSize(1048576); // "1.00 MB"

// Validate quota
const canUpload = validateQuota(500000, 1000000, 300000); // true

// Get usage percentage
const usage = getQuotaUsagePercentage(750000, 1000000); // 75
```

## Advanced Examples

See the [examples.ts](./examples.ts) file for comprehensive usage examples including:

- Basic filesystem operations
- File and blob management
- Advanced tools usage
- Error handling patterns
- Retry logic implementation

## TypeScript Support

The client is written in TypeScript and provides complete type definitions for all API operations. All request and response types are exported for use in your applications.

```typescript
import type { 
  Filesystem, 
  Directory, 
  File, 
  Blob, 
  Symlink,
  APIResponse 
} from '@herolib/herofs-client';
```

## Browser Support

The client uses the standard `fetch` API and supports all modern browsers. For Node.js environments, ensure you have Node.js 18+ or install a fetch polyfill.

## Contributing

This client is part of the HeroLib project. Please see the main repository for contribution guidelines.

## License

MIT License - see the LICENSE file for details.

## Related

- [HeroFS Server Documentation](../README.md)
- [HeroLib Main Repository](https://github.com/freeflowuniverse/herolib)
- [HeroFS API Specification](../handlers_common.v)
