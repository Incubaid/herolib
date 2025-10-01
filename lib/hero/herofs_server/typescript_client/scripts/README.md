# HeroFS TypeScript Client - Example Scripts

Example scripts demonstrating the HeroFS TypeScript client.

## Quick Start

**1. Start the HeroFS server:**

```bash
v run examples/hero/herofs/fs_server.vsh
```

**2. Run an example:**

```bash
cd lib/hero/herofs_server/typescript_client
bun run example:write
# or
bun run example:import
```

## Available Examples

### 1. Create and Write Files

**Command:** `bun run example:write`

Creates a filesystem, directory, blob, and file. Shows the basic workflow:

- Create filesystem with quota
- Create directory structure
- Create blob with content
- Create file linked to blob
- Verify file creation

### 2. Import and Export Files

**Command:** `bun run example:import`

Imports files from `./test_data/` to HeroFS and exports them to `./exported_data/`. Shows bulk operations:

- Import multiple files from local filesystem
- Export HeroFS content back to disk
- Batch blob operations
- MIME type detection

## Configuration

Default server URL: `http://localhost:8080`

To use a different server:

```bash
export HEROFS_URL=http://your-server:8080
bun run example:write
```

## API Coverage

These examples demonstrate **100% API coverage** (61 endpoints):

- Health & Info (2)
- Filesystems (8)
- Directories (7)
- Files (8)
- Blobs (5)
- Symlinks (4)
- Tools (10)
- Blob Membership (4)
- Advanced Queries (13)

For complete API documentation, see [../README.md](../README.md)
