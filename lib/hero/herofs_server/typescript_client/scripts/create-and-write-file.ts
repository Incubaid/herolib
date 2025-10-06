#!/usr/bin/env bun

/**
 * HeroFS TypeScript Client Example: Create and Write File
 *
 * Demonstrates the complete workflow for creating and writing files in HeroFS.
 *
 * Usage:
 *   bun run scripts/create-and-write-file.ts
 *   # or
 *   bun run example:write
 */

import { HeroFSClient } from '../index.js';
import type { Filesystem, Directory } from '../types.js';

// Configuration
const HEROFS_URL = process.env.HEROFS_URL || 'http://localhost:8080';
const EXAMPLE_FILESYSTEM_NAME = 'example_fs';
const EXAMPLE_DIR_NAME = 'documents';
const EXAMPLE_FILE_NAME = 'welcome.txt';
const SAMPLE_CONTENT = `Welcome to HeroFS!

This is a sample file created using the HeroFS TypeScript client.

HeroFS Features:
- Distributed filesystem architecture
- Blob-based content storage
- RESTful API interface
- TypeScript client with 100% API coverage

Created at: ${new Date().toISOString()}
`;

/**
 * Main execution function
 */
async function main(): Promise<void> {
  console.log('🚀 HeroFS TypeScript Client Example: Create and Write File');
  console.log('='.repeat(65));

  try {
    // Step 1: Connect to HeroFS server
    console.log('\n�� Step 1: Connecting to HeroFS server...');
    const client = new HeroFSClient({ baseUrl: HEROFS_URL });

    const health = await client.healthCheck();
    if (!health.success) {
      throw new Error(`Health check failed: ${health.error}`);
    }
    console.log(`✅ Connected to HeroFS server at ${HEROFS_URL}`);

    // Step 2: Create or get filesystem
    console.log('\n🗂️  Step 2: Setting up filesystem...');
    let filesystem: Filesystem;

    // Try to get existing filesystem, create if not found
    try {
      const existingFs = await client.getFilesystemByName(EXAMPLE_FILESYSTEM_NAME);
      if (existingFs.success && existingFs.data) {
        filesystem = existingFs.data;
        console.log(`✅ Using existing filesystem: ${filesystem.name} (ID: ${filesystem.id})`);
      } else {
        throw new Error('Filesystem not found');
      }
    } catch (error) {
      // Filesystem doesn't exist, create it
      console.log(`   Filesystem '${EXAMPLE_FILESYSTEM_NAME}' not found, creating...`);
      const newFs = await client.createFilesystem({
        name: EXAMPLE_FILESYSTEM_NAME,
        description: 'Example filesystem for TypeScript client demo',
        quota_bytes: 100 * 1024 * 1024, // 100MB
      });

      if (!newFs.success || !newFs.data) {
        throw new Error(`Failed to create filesystem: ${newFs.error}`);
      }

      filesystem = newFs.data;
      console.log(`✅ Created new filesystem: ${filesystem.name} (ID: ${filesystem.id})`);
    }

    // Step 3: Create or get directory
    console.log('\n📁 Step 3: Setting up directory...');
    let directory: Directory;

    const dirs = await client.listDirectoriesByFilesystem(filesystem.id!);
    const existingDir = dirs.success && dirs.data ?
      dirs.data.find(d => d.name === EXAMPLE_DIR_NAME) : null;

    if (existingDir) {
      directory = existingDir;
      console.log(`✅ Using existing directory: ${directory.name} (ID: ${directory.id})`);
    } else {
      const newDir = await client.createDirectory({
        fs_id: filesystem.id!,
        name: EXAMPLE_DIR_NAME,
        description: 'Documents directory for examples',
      });

      if (!newDir.success || !newDir.data) {
        throw new Error(`Failed to create directory: ${newDir.error}`);
      }

      directory = newDir.data;
      console.log(`✅ Created new directory: ${directory.name} (ID: ${directory.id})`);
    }

    // Step 4: Create blob with content
    console.log('\n💾 Step 4: Creating blob with content...');
    const contentBytes = new TextEncoder().encode(SAMPLE_CONTENT);
    const blob = await client.createBlob({
      data: Array.from(contentBytes),
      mime_type: 'text/plain',
    });

    if (!blob.success || !blob.data) {
      throw new Error(`Failed to create blob: ${blob.error}`);
    }

    console.log(`✅ Created blob: ${blob.data.hash}`);
    console.log(`   Size: ${blob.data.size_bytes} bytes`);

    // Step 5: Create file linked to blob
    console.log('\n📄 Step 5: Creating file...');
    const file = await client.createFile({
      fs_id: filesystem.id!,
      directories: [directory.id!],
      blobs: [blob.data.id!],
      name: EXAMPLE_FILE_NAME,
      description: 'Welcome file created by TypeScript client example',
      mime_type: 'text/plain' as any,
    });

    if (!file.success || !file.data) {
      throw new Error(`Failed to create file: ${file.error}`);
    }

    console.log(`✅ Created file: ${file.data.name} (ID: ${file.data.id})`);
    console.log(`   Path: /${filesystem.name}/${directory.name}/${file.data.name}`);

    // Step 6: Summary
    console.log('\n🎉 Success! File creation workflow completed.');
    console.log('\n📊 Summary:');
    console.log(`   Filesystem: ${filesystem.name} (ID: ${filesystem.id})`);
    console.log(`   Directory: ${directory.name} (ID: ${directory.id})`);
    console.log(`   File: ${file.data.name} (ID: ${file.data.id})`);
    console.log(`   Blob: ${blob.data.hash}`);

  } catch (error) {
    console.error('\n❌ Error occurred:');
    console.error(`   ${error instanceof Error ? error.message : String(error)}`);
    console.error('\n🔧 Troubleshooting:');
    console.error(`   1. Ensure HeroFS server is running at ${HEROFS_URL}`);
    console.error('   2. Check server logs for detailed error information');
    process.exit(1);
  }
}

// Execute the main function when script is run directly
main().catch(console.error);
