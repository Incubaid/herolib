#!/usr/bin/env bun

/**
 * HeroFS TypeScript Client Example: Import and Export Operations
 *
 * Demonstrates bulk operations and data management in HeroFS:
 * - Importing multiple files from local filesystem
 * - Exporting HeroFS content to local filesystem
 * - Batch blob operations
 * - Directory synchronization
 *
 * Usage:
 *   bun run scripts/import-export-operations.ts
 *   # or
 *   bun run example:import
 */

import { HeroFSClient } from '../index.js';
import type { Filesystem, Directory, File, Blob } from '../types.js';
import { readdir, readFile, writeFile, mkdir } from 'fs/promises';
import { join, extname } from 'path';
import { existsSync } from 'fs';

// Configuration
const HEROFS_URL = process.env.HEROFS_URL || 'http://localhost:8080';
const IMPORT_FILESYSTEM_NAME = 'import_export_demo';
const IMPORT_DIR = './test_data'; // Directory to import from
const EXPORT_DIR = './exported_data'; // Directory to export to

/**
 * Get MIME type from file extension
 */
function getMimeType(filename: string): string {
  const ext = extname(filename).toLowerCase();
  const mimeTypes: Record<string, string> = {
    '.txt': 'text/plain',
    '.md': 'text/markdown',
    '.json': 'application/json',
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'application/javascript',
    '.ts': 'application/typescript',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.pdf': 'application/pdf',
  };
  return mimeTypes[ext] || 'application/octet-stream';
}

/**
 * Create test data directory with sample files
 */
async function createTestData(): Promise<void> {
  if (!existsSync(IMPORT_DIR)) {
    await mkdir(IMPORT_DIR, { recursive: true });

    // Create sample files
    const sampleFiles = [
      { name: 'readme.txt', content: 'This is a sample README file for import/export demo.' },
      { name: 'config.json', content: JSON.stringify({ version: '1.0', enabled: true }, null, 2) },
      { name: 'notes.md', content: '# Notes\n\nThis is a markdown file.\n\n- Item 1\n- Item 2' },
      { name: 'data.txt', content: 'Sample data file with some content for testing.' },
    ];

    for (const file of sampleFiles) {
      await writeFile(join(IMPORT_DIR, file.name), file.content, 'utf-8');
    }

    console.log(`✅ Created test data directory: ${IMPORT_DIR}`);
  }
}

/**
 * Import files from local filesystem to HeroFS
 */
async function importFiles(
  client: HeroFSClient,
  filesystem: Filesystem,
  directory: Directory,
  importPath: string
): Promise<File[]> {
  console.log(`\n📥 Importing files from ${importPath}...`);

  const files = await readdir(importPath);
  const importedFiles: File[] = [];

  for (const filename of files) {
    const filePath = join(importPath, filename);

    try {
      // Read file content
      const content = await readFile(filePath);
      const contentBytes = Array.from(content);

      console.log(`   Processing: ${filename} (${content.length} bytes)`);

      // Create blob
      const blob = await client.createBlob({
        data: contentBytes,
        mime_type: getMimeType(filename),
        name: filename,
      });

      if (!blob.success || !blob.data) {
        console.error(`   ❌ Failed to create blob for ${filename}: ${blob.error}`);
        continue;
      }

      // Create file
      const file = await client.createFile({
        fs_id: filesystem.id!,
        directories: [directory.id!],
        blobs: [blob.data.id!],
        name: filename,
        description: `Imported from ${importPath}`,
        mime_type: getMimeType(filename) as any,
      });

      if (!file.success || !file.data) {
        console.error(`   ❌ Failed to create file ${filename}: ${file.error}`);
        continue;
      }

      importedFiles.push(file.data);
      console.log(`   ✅ Imported: ${filename} (File ID: ${file.data.id}, Blob: ${blob.data.hash?.substring(0, 8)}...)`);

    } catch (error) {
      console.error(`   ❌ Error importing ${filename}:`, error instanceof Error ? error.message : String(error));
    }
  }

  return importedFiles;
}

/**
 * Export files from HeroFS to local filesystem
 */
async function exportFiles(
  client: HeroFSClient,
  directory: Directory,
  exportPath: string
): Promise<number> {
  console.log(`\n📤 Exporting files to ${exportPath}...`);

  // Create export directory
  if (!existsSync(exportPath)) {
    await mkdir(exportPath, { recursive: true });
  }

  // List files in directory
  const filesResponse = await client.listFilesByDirectory(directory.id!);
  if (!filesResponse.success || !filesResponse.data) {
    throw new Error(`Failed to list files: ${filesResponse.error}`);
  }

  const files = filesResponse.data;
  console.log(`   Found ${files.length} files in directory ${directory.id}`);
  let exportedCount = 0;

  for (const file of files) {
    try {
      // Skip files without names
      if (!file.name) {
        console.log(`   ⚠️  Skipping file without name`);
        continue;
      }

      // Get blob IDs for the file
      if (!file.blobs || file.blobs.length === 0) {
        console.log(`   ⚠️  Skipping ${file.name}: No blobs attached`);
        continue;
      }

      // Get the first blob (for simplicity)
      const blobId = file.blobs[0];
      const blobResponse = await client.getBlob(blobId);

      if (!blobResponse.success || !blobResponse.data) {
        console.error(`   ❌ Failed to get blob ${blobId}: ${blobResponse.error}`);
        continue;
      }

      const blob = blobResponse.data;

      // Convert blob data to buffer
      if (!blob.data) {
        console.log(`   ⚠️  Skipping ${file.name}: No blob data`);
        continue;
      }

      const buffer = Buffer.from(blob.data);
      const exportFilePath = join(exportPath, file.name);

      // Write to file
      await writeFile(exportFilePath, buffer);

      exportedCount++;
      console.log(`   ✅ Exported: ${file.name} (${buffer.length} bytes)`);

    } catch (error) {
      console.error(`   ❌ Error exporting file:`, error instanceof Error ? error.message : String(error));
    }
  }

  return exportedCount;
}

/**
 * Batch blob operations - create multiple blobs efficiently
 */
async function batchBlobOperations(client: HeroFSClient): Promise<Blob[]> {
  console.log('\n🔄 Performing batch blob operations...');

  const batchData = [
    { name: 'batch1.txt', content: 'First batch item' },
    { name: 'batch2.txt', content: 'Second batch item' },
    { name: 'batch3.txt', content: 'Third batch item' },
  ];

  const blobs: Blob[] = [];

  for (const item of batchData) {
    const contentBytes = Array.from(new TextEncoder().encode(item.content));
    const blob = await client.createBlob({
      data: contentBytes,
      mime_type: 'text/plain',
      name: item.name,
    });

    if (blob.success && blob.data) {
      blobs.push(blob.data);
      console.log(`   ✅ Created blob: ${item.name} (${blob.data.hash?.substring(0, 8)}...)`);
    }
  }

  return blobs;
}

/**
 * Main execution function
 */
async function main(): Promise<void> {
  console.log('🚀 HeroFS TypeScript Client Example: Import/Export Operations');
  console.log('='.repeat(70));

  try {
    // Step 1: Connect to HeroFS server
    console.log('\n📡 Step 1: Connecting to HeroFS server...');
    const client = new HeroFSClient({ baseUrl: HEROFS_URL });

    const health = await client.healthCheck();
    if (!health.success) {
      throw new Error(`Health check failed: ${health.error}`);
    }
    console.log(`✅ Connected to HeroFS server at ${HEROFS_URL}`);

    // Step 2: Setup filesystem
    console.log('\n🗂️  Step 2: Setting up filesystem...');
    let filesystem: Filesystem;

    // Try to get existing filesystem, create if not found
    try {
      const existingFs = await client.getFilesystemByName(IMPORT_FILESYSTEM_NAME);
      if (existingFs.success && existingFs.data) {
        filesystem = existingFs.data;
        console.log(`✅ Using existing filesystem: ${filesystem.name} (ID: ${filesystem.id})`);
      } else {
        throw new Error('Filesystem not found');
      }
    } catch (error) {
      // Filesystem doesn't exist, create it
      console.log(`   Filesystem '${IMPORT_FILESYSTEM_NAME}' not found, creating...`);
      const newFs = await client.createFilesystem({
        name: IMPORT_FILESYSTEM_NAME,
        description: 'Filesystem for import/export demo',
        quota_bytes: 500 * 1024 * 1024, // 500MB
      });

      if (!newFs.success || !newFs.data) {
        throw new Error(`Failed to create filesystem: ${newFs.error}`);
      }

      filesystem = newFs.data;
      console.log(`✅ Created new filesystem: ${filesystem.name} (ID: ${filesystem.id})`);
    }

    // Step 3: Setup directory
    console.log('\n📁 Step 3: Setting up directory...');
    let directory: Directory;

    const dirs = await client.listDirectoriesByFilesystem(filesystem.id!);
    const existingDir = dirs.success && dirs.data ?
      dirs.data.find(d => d.name === 'imports') : null;

    if (existingDir) {
      directory = existingDir;
      console.log(`✅ Using existing directory: ${directory.name} (ID: ${directory.id})`);
    } else {
      const newDir = await client.createDirectory({
        fs_id: filesystem.id!,
        name: 'imports',
        description: 'Directory for imported files',
      });

      if (!newDir.success || !newDir.data) {
        throw new Error(`Failed to create directory: ${newDir.error}`);
      }

      directory = newDir.data;
      console.log(`✅ Created new directory: ${directory.name} (ID: ${directory.id})`);
    }

    // Step 4: Create test data
    console.log('\n📝 Step 4: Preparing test data...');
    await createTestData();

    // Step 5: Import files
    const importedFiles = await importFiles(client, filesystem, directory, IMPORT_DIR);
    console.log(`\n✅ Import complete: ${importedFiles.length} files imported`);

    // Step 6: Batch blob operations
    const batchBlobs = await batchBlobOperations(client);
    console.log(`\n✅ Batch operations complete: ${batchBlobs.length} blobs created`);

    // Step 7: Export files
    const exportedCount = await exportFiles(client, directory, EXPORT_DIR);
    console.log(`\n✅ Export complete: ${exportedCount} files exported to ${EXPORT_DIR}`);

    // Step 8: Summary
    console.log('\n🎉 Success! Import/Export operations completed.');
    console.log('\n📊 Summary:');
    console.log(`   Filesystem: ${filesystem.name} (ID: ${filesystem.id})`);
    console.log(`   Directory: ${directory.name} (ID: ${directory.id})`);
    console.log(`   Files imported: ${importedFiles.length}`);
    console.log(`   Files exported: ${exportedCount}`);
    console.log(`   Batch blobs created: ${batchBlobs.length}`);
    console.log(`\n💡 Check the exported files in: ${EXPORT_DIR}`);

  } catch (error) {
    console.error('\n❌ Error occurred:');
    console.error(`   ${error instanceof Error ? error.message : String(error)}`);
    console.error('\n🔧 Troubleshooting:');
    console.error(`   1. Ensure HeroFS server is running at ${HEROFS_URL}`);
    console.error('   2. Check server logs for detailed error information');
    console.error('   3. Verify file permissions for import/export directories');
    process.exit(1);
  }
}

// Execute the main function when script is run directly
main().catch(console.error);

