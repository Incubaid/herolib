/**
 * HeroFS TypeScript Client - Main Export
 * 
 * A comprehensive TypeScript client for the HeroFS distributed filesystem REST API.
 * Provides type-safe access to all 50+ endpoints with proper error handling and CORS support.
 * 
 * @example
 * ```typescript
 * import { HeroFSClient, MimeType, SymlinkTargetType } from '@herolib/herofs-client';
 * 
 * const client = new HeroFSClient({ baseUrl: 'http://localhost:8080' });
 * 
 * // Create a filesystem
 * const fs = await client.createFilesystem({
 *   name: 'my_filesystem',
 *   description: 'My test filesystem',
 *   quota_bytes: 1073741824
 * });
 * 
 * // Create a directory
 * const dir = await client.createDirectory({
 *   name: 'documents',
 *   fs_id: fs.data.id,
 *   parent_id: 0
 * });
 * 
 * // Create a file with blob content
 * const content = new TextEncoder().encode('Hello, HeroFS!');
 * const blob = await client.createBlob({
 *   data: Array.from(content),
 *   mime_type: 'text/plain'
 * });
 * 
 * const file = await client.createFile({
 *   name: 'hello.txt',
 *   fs_id: fs.data.id,
 *   directories: [dir.data.id],
 *   blobs: [blob.data.id],
 *   mime_type: MimeType.TEXT
 * });
 * ```
 */

// Export main client class and error class
export { HeroFSClient, HeroFSError } from './client';

// Export all type definitions
export * from './types';

// Re-export commonly used types for convenience
export type {
  APIResponse,
  ErrorResponse,
  HeroFSClientConfig,
  RequestOptions,
  Filesystem,
  FilesystemCreateRequest,
  FilesystemUpdateRequest,
  Directory,
  DirectoryCreateRequest,
  DirectoryUpdateRequest,
  File,
  FileCreateRequest,
  FileUpdateRequest,
  Blob,
  BlobCreateRequest,
  BlobUpdateRequest,
  Symlink,
  SymlinkCreateRequest,
  SymlinkUpdateRequest,
  APIInfo
} from './types';

// Version information
export const VERSION = '1.0.0';

/**
 * Create a new HeroFS client with default configuration
 * 
 * @param baseUrl - Base URL of the HeroFS server (default: http://localhost:8080)
 * @param config - Additional client configuration
 * @returns Configured HeroFS client instance
 */
export function createClient(baseUrl?: string, config?: Partial<HeroFSClientConfig>): HeroFSClient {
  return new HeroFSClient({
    baseUrl: baseUrl || 'http://localhost:8080',
    ...config
  });
}

/**
 * Default client instance for quick usage
 * Uses http://localhost:8080 as the default base URL
 */
export const defaultClient = createClient();

/**
 * Utility function to check if an error is a HeroFS API error
 * 
 * @param error - Error to check
 * @returns True if error is a HeroFSError
 */
export function isHeroFSError(error: any): error is HeroFSError {
  return error instanceof HeroFSError;
}

/**
 * Utility function to create a retry wrapper for any async operation
 * 
 * @param operation - Async operation to retry
 * @param maxRetries - Maximum number of retry attempts (default: 3)
 * @param baseDelay - Base delay in milliseconds (default: 1000)
 * @returns Promise that resolves with the operation result
 */
export async function withRetry<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (isHeroFSError(error) && error.isServerError() && attempt < maxRetries) {
        const delay = baseDelay * Math.pow(2, attempt - 1);
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw error;
    }
  }
  throw new Error('Max retries exceeded');
}

/**
 * Utility function to convert a string to a byte array for blob operations
 * 
 * @param text - Text to convert
 * @param encoding - Text encoding (default: utf-8)
 * @returns Byte array suitable for blob creation
 */
export function textToBytes(text: string, encoding: string = 'utf-8'): number[] {
  const encoder = new TextEncoder();
  return Array.from(encoder.encode(text));
}

/**
 * Utility function to convert a byte array to a string
 * 
 * @param bytes - Byte array to convert
 * @param encoding - Text encoding (default: utf-8)
 * @returns Decoded string
 */
export function bytesToText(bytes: number[], encoding: string = 'utf-8'): string {
  const decoder = new TextDecoder(encoding);
  return decoder.decode(new Uint8Array(bytes));
}

/**
 * Utility function to format file sizes in human-readable format
 * 
 * @param bytes - Size in bytes
 * @param decimals - Number of decimal places (default: 2)
 * @returns Formatted size string (e.g., "1.5 MB")
 */
export function formatFileSize(bytes: number, decimals: number = 2): string {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

/**
 * Utility function to validate filesystem quota
 * 
 * @param usedBytes - Currently used bytes
 * @param quotaBytes - Total quota in bytes
 * @param additionalBytes - Additional bytes to check
 * @returns True if the additional bytes would fit within quota
 */
export function validateQuota(usedBytes: number, quotaBytes: number, additionalBytes: number): boolean {
  if (quotaBytes === 0) return true; // Unlimited quota
  return (usedBytes + additionalBytes) <= quotaBytes;
}

/**
 * Utility function to calculate quota usage percentage
 * 
 * @param usedBytes - Currently used bytes
 * @param quotaBytes - Total quota in bytes
 * @returns Usage percentage (0-100)
 */
export function getQuotaUsagePercentage(usedBytes: number, quotaBytes: number): number {
  if (quotaBytes === 0) return 0; // Unlimited quota
  return Math.min(100, (usedBytes / quotaBytes) * 100);
}

// Default export for convenience
export default HeroFSClient;
