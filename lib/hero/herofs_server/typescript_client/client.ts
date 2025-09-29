/**
 * HeroFS REST API TypeScript Client
 * 
 * A comprehensive TypeScript client for the HeroFS distributed filesystem REST API.
 * Provides type-safe access to all 50+ endpoints with proper error handling and CORS support.
 * 
 * @example
 * ```typescript
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
 * ```
 */

import {
  APIResponse,
  ErrorResponse,
  HeroFSClientConfig,
  RequestOptions,
  Filesystem,
  FilesystemCreateRequest,
  FilesystemUpdateRequest,
  UsageRequest,
  QuotaCheckRequest,
  Directory,
  DirectoryCreateRequest,
  DirectoryUpdateRequest,
  DirectoryPathRequest,
  File,
  FileCreateRequest,
  FileUpdateRequest,
  FileDirectoryRequest,
  FileMetadataRequest,
  Blob,
  BlobCreateRequest,
  BlobUpdateRequest,
  Symlink,
  SymlinkCreateRequest,
  SymlinkUpdateRequest,
  ToolsListRequest,
  ToolsFindRequest,
  ToolsCopyRequest,
  ToolsMoveRequest,
  ToolsRemoveRequest,
  ToolsImportFileRequest,
  ToolsImportDirectoryRequest,
  ToolsExportFileRequest,
  ToolsExportDirectoryRequest,
  ToolsContentRequest,
  APIInfo
} from './types';

/**
 * HeroFS REST API Client
 * 
 * Provides comprehensive access to the HeroFS distributed filesystem API
 * with full TypeScript support and error handling.
 */
export class HeroFSClient {
  private baseUrl: string;
  private timeout: number;
  private defaultHeaders: Record<string, string>;

  constructor(config: HeroFSClientConfig = {}) {
    this.baseUrl = config.baseUrl || 'http://localhost:8080';
    this.timeout = config.timeout || 30000;
    this.defaultHeaders = {
      'Content-Type': 'application/json',
      ...config.headers
    };
  }

  // =============================================================================
  // PRIVATE UTILITY METHODS
  // =============================================================================

  private async request<T>(
    method: string,
    endpoint: string,
    data?: any,
    options?: RequestOptions
  ): Promise<APIResponse<T>> {
    const url = `${this.baseUrl}${endpoint}`;
    const headers = { ...this.defaultHeaders, ...options?.headers };
    const timeout = options?.timeout || this.timeout;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url, {
        method,
        headers,
        body: data ? JSON.stringify(data) : null,
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorData: ErrorResponse = await response.json();
        throw new HeroFSError(
          errorData.error || `HTTP ${response.status}`,
          response.status,
          errorData.message || response.statusText
        );
      }

      const result: APIResponse<T> = await response.json();

      if (!result.success) {
        throw new HeroFSError(
          result.error || 'API Error',
          response.status,
          result.message || 'Unknown error occurred'
        );
      }

      return result;
    } catch (error) {
      clearTimeout(timeoutId);

      if (error instanceof HeroFSError) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new HeroFSError('Request timeout', 408, `Request timed out after ${timeout}ms`);
      }

      throw new HeroFSError(
        'Network Error',
        0,
        error instanceof Error ? error.message : 'Failed to connect to HeroFS server'
      );
    }
  }

  private async get<T>(endpoint: string, options?: RequestOptions): Promise<APIResponse<T>> {
    return this.request<T>('GET', endpoint, undefined, options);
  }

  private async post<T>(endpoint: string, data?: any, options?: RequestOptions): Promise<APIResponse<T>> {
    return this.request<T>('POST', endpoint, data, options);
  }

  private async put<T>(endpoint: string, data?: any, options?: RequestOptions): Promise<APIResponse<T>> {
    return this.request<T>('PUT', endpoint, data, options);
  }

  private async delete<T>(endpoint: string, options?: RequestOptions): Promise<APIResponse<T>> {
    return this.request<T>('DELETE', endpoint, undefined, options);
  }

  // =============================================================================
  // HEALTH & API INFO ENDPOINTS
  // =============================================================================

  /**
   * Check server health status
   */
  async healthCheck(options?: RequestOptions): Promise<APIResponse<string>> {
    return this.get<string>('/health', options);
  }

  /**
   * Get API information and available endpoints
   */
  async getAPIInfo(options?: RequestOptions): Promise<APIResponse<APIInfo>> {
    return this.get<APIInfo>('/api', options);
  }

  // =============================================================================
  // FILESYSTEM ENDPOINTS
  // =============================================================================

  /**
   * List all filesystems
   */
  async listFilesystems(options?: RequestOptions): Promise<APIResponse<Filesystem[]>> {
    return this.get<Filesystem[]>('/api/fs', options);
  }

  /**
   * Get filesystem by ID
   */
  async getFilesystem(id: number, options?: RequestOptions): Promise<APIResponse<Filesystem>> {
    return this.get<Filesystem>(`/api/fs/${id}`, options);
  }

  /**
   * Create new filesystem
   */
  async createFilesystem(
    data: FilesystemCreateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Filesystem>> {
    return this.post<Filesystem>('/api/fs', data, options);
  }

  /**
   * Update filesystem
   */
  async updateFilesystem(
    id: number,
    data: FilesystemUpdateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Filesystem>> {
    return this.put<Filesystem>(`/api/fs/${id}`, data, options);
  }

  /**
   * Delete filesystem
   */
  async deleteFilesystem(id: number, options?: RequestOptions): Promise<APIResponse<boolean>> {
    return this.delete<boolean>(`/api/fs/${id}`, options);
  }

  /**
   * Check if filesystem exists
   */
  async filesystemExists(id: number, options?: RequestOptions): Promise<APIResponse<boolean>> {
    return this.get<boolean>(`/api/fs/${id}/exists`, options);
  }

  /**
   * Increase filesystem usage
   */
  async increaseFilesystemUsage(
    id: number,
    data: UsageRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Filesystem>> {
    return this.post<Filesystem>(`/api/fs/${id}/usage/increase`, data, options);
  }

  /**
   * Decrease filesystem usage
   */
  async decreaseFilesystemUsage(
    id: number,
    data: UsageRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Filesystem>> {
    return this.post<Filesystem>(`/api/fs/${id}/usage/decrease`, data, options);
  }

  /**
   * Check filesystem quota
   */
  async checkFilesystemQuota(
    id: number,
    data: QuotaCheckRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>(`/api/fs/${id}/quota/check`, data, options);
  }

  // =============================================================================
  // DIRECTORY ENDPOINTS
  // =============================================================================

  /**
   * List all directories
   */
  async listDirectories(options?: RequestOptions): Promise<APIResponse<Directory[]>> {
    return this.get<Directory[]>('/api/dirs', options);
  }

  /**
   * Get directory by ID
   */
  async getDirectory(id: number, options?: RequestOptions): Promise<APIResponse<Directory>> {
    return this.get<Directory>(`/api/dirs/${id}`, options);
  }

  /**
   * Create new directory
   */
  async createDirectory(
    data: DirectoryCreateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Directory>> {
    return this.post<Directory>('/api/dirs', data, options);
  }

  /**
   * Update directory
   */
  async updateDirectory(
    id: number,
    data: DirectoryUpdateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Directory>> {
    return this.put<Directory>(`/api/dirs/${id}`, data, options);
  }

  /**
   * Delete directory
   */
  async deleteDirectory(id: number, options?: RequestOptions): Promise<APIResponse<boolean>> {
    return this.delete<boolean>(`/api/dirs/${id}`, options);
  }

  /**
   * Create directory path
   */
  async createDirectoryPath(
    data: DirectoryPathRequest,
    options?: RequestOptions
  ): Promise<APIResponse<number>> {
    return this.post<number>('/api/dirs/create-path', data, options);
  }

  /**
   * Check if directory has children
   */
  async directoryHasChildren(id: number, options?: RequestOptions): Promise<APIResponse<boolean>> {
    return this.get<boolean>(`/api/dirs/${id}/has-children`, options);
  }

  /**
   * Get directory children
   */
  async getDirectoryChildren(id: number, options?: RequestOptions): Promise<APIResponse<Directory[]>> {
    return this.get<Directory[]>(`/api/dirs/${id}/children`, options);
  }

  // =============================================================================
  // FILE ENDPOINTS
  // =============================================================================

  /**
   * List all files
   */
  async listFiles(options?: RequestOptions): Promise<APIResponse<File[]>> {
    return this.get<File[]>('/api/files', options);
  }

  /**
   * Get file by ID
   */
  async getFile(id: number, options?: RequestOptions): Promise<APIResponse<File>> {
    return this.get<File>(`/api/files/${id}`, options);
  }

  /**
   * Create new file
   */
  async createFile(
    data: FileCreateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<File>> {
    return this.post<File>('/api/files', data, options);
  }

  /**
   * Update file
   */
  async updateFile(
    id: number,
    data: FileUpdateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<File>> {
    return this.put<File>(`/api/files/${id}`, data, options);
  }

  /**
   * Delete file
   */
  async deleteFile(id: number, options?: RequestOptions): Promise<APIResponse<boolean>> {
    return this.delete<boolean>(`/api/files/${id}`, options);
  }

  /**
   * Add file to directory
   */
  async addFileToDirectory(
    id: number,
    data: FileDirectoryRequest,
    options?: RequestOptions
  ): Promise<APIResponse<File>> {
    return this.post<File>(`/api/files/${id}/add-to-directory`, data, options);
  }

  /**
   * Remove file from directory
   */
  async removeFileFromDirectory(
    id: number,
    data: FileDirectoryRequest,
    options?: RequestOptions
  ): Promise<APIResponse<File>> {
    return this.post<File>(`/api/files/${id}/remove-from-directory`, data, options);
  }

  /**
   * Update file metadata
   */
  async updateFileMetadata(
    id: number,
    data: FileMetadataRequest,
    options?: RequestOptions
  ): Promise<APIResponse<File>> {
    return this.post<File>(`/api/files/${id}/metadata`, data, options);
  }

  /**
   * Update file accessed timestamp
   */
  async updateFileAccessed(id: number, options?: RequestOptions): Promise<APIResponse<File>> {
    return this.post<File>(`/api/files/${id}/accessed`, {}, options);
  }

  /**
   * List files by filesystem
   */
  async listFilesByFilesystem(fsId: number, options?: RequestOptions): Promise<APIResponse<File[]>> {
    return this.get<File[]>(`/api/files/by-filesystem/${fsId}`, options);
  }

  // =============================================================================
  // BLOB ENDPOINTS
  // =============================================================================

  /**
   * List all blobs
   */
  async listBlobs(options?: RequestOptions): Promise<APIResponse<Blob[]>> {
    return this.get<Blob[]>('/api/blobs', options);
  }

  /**
   * Get blob by ID
   */
  async getBlob(id: number, options?: RequestOptions): Promise<APIResponse<Blob>> {
    return this.get<Blob>(`/api/blobs/${id}`, options);
  }

  /**
   * Create new blob
   */
  async createBlob(
    data: BlobCreateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Blob>> {
    return this.post<Blob>('/api/blobs', data, options);
  }

  /**
   * Update blob
   */
  async updateBlob(
    id: number,
    data: BlobUpdateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Blob>> {
    return this.put<Blob>(`/api/blobs/${id}`, data, options);
  }

  /**
   * Delete blob
   */
  async deleteBlob(id: number, options?: RequestOptions): Promise<APIResponse<boolean>> {
    return this.delete<boolean>(`/api/blobs/${id}`, options);
  }

  /**
   * Get blob content
   */
  async getBlobContent(id: number, options?: RequestOptions): Promise<APIResponse<number[]>> {
    return this.get<number[]>(`/api/blobs/${id}/content`, options);
  }

  // =============================================================================
  // SYMLINK ENDPOINTS
  // =============================================================================

  /**
   * List all symlinks
   */
  async listSymlinks(options?: RequestOptions): Promise<APIResponse<Symlink[]>> {
    return this.get<Symlink[]>('/api/symlinks', options);
  }

  /**
   * Get symlink by ID
   */
  async getSymlink(id: number, options?: RequestOptions): Promise<APIResponse<Symlink>> {
    return this.get<Symlink>(`/api/symlinks/${id}`, options);
  }

  /**
   * Create new symlink
   */
  async createSymlink(
    data: SymlinkCreateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Symlink>> {
    return this.post<Symlink>('/api/symlinks', data, options);
  }

  /**
   * Update symlink
   */
  async updateSymlink(
    id: number,
    data: SymlinkUpdateRequest,
    options?: RequestOptions
  ): Promise<APIResponse<Symlink>> {
    return this.put<Symlink>(`/api/symlinks/${id}`, data, options);
  }

  /**
   * Delete symlink
   */
  async deleteSymlink(id: number, options?: RequestOptions): Promise<APIResponse<boolean>> {
    return this.delete<boolean>(`/api/symlinks/${id}`, options);
  }

  // =============================================================================
  // TOOLS ENDPOINTS
  // =============================================================================

  /**
   * List directory contents
   */
  async toolsList(
    data: ToolsListRequest,
    options?: RequestOptions
  ): Promise<APIResponse<any[]>> {
    return this.post<any[]>('/api/tools/list', data, options);
  }

  /**
   * Find files by pattern
   */
  async toolsFind(
    data: ToolsFindRequest,
    options?: RequestOptions
  ): Promise<APIResponse<any[]>> {
    return this.post<any[]>('/api/tools/find', data, options);
  }

  /**
   * Copy file or directory
   */
  async toolsCopy(
    data: ToolsCopyRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>('/api/tools/copy', data, options);
  }

  /**
   * Move file or directory
   */
  async toolsMove(
    data: ToolsMoveRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>('/api/tools/move', data, options);
  }

  /**
   * Remove file or directory
   */
  async toolsRemove(
    data: ToolsRemoveRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>('/api/tools/remove', data, options);
  }

  /**
   * Import file from real filesystem
   */
  async toolsImportFile(
    data: ToolsImportFileRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>('/api/tools/import/file', data, options);
  }

  /**
   * Import directory from real filesystem
   */
  async toolsImportDirectory(
    data: ToolsImportDirectoryRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>('/api/tools/import/directory', data, options);
  }

  /**
   * Export file to real filesystem
   */
  async toolsExportFile(
    data: ToolsExportFileRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>('/api/tools/export/file', data, options);
  }

  /**
   * Export directory to real filesystem
   */
  async toolsExportDirectory(
    data: ToolsExportDirectoryRequest,
    options?: RequestOptions
  ): Promise<APIResponse<boolean>> {
    return this.post<boolean>('/api/tools/export/directory', data, options);
  }

  /**
   * Get file content by filesystem and path
   */
  async toolsContent(
    fsId: number,
    data: ToolsContentRequest,
    options?: RequestOptions
  ): Promise<APIResponse<string>> {
    return this.post<string>(`/api/tools/content/${fsId}`, data, options);
  }
}

/**
 * Custom error class for HeroFS API errors
 */
export class HeroFSError extends Error {
  public readonly statusCode: number;
  public readonly userMessage: string;

  constructor(message: string, statusCode: number, userMessage?: string) {
    super(message);
    this.name = 'HeroFSError';
    this.statusCode = statusCode;
    this.userMessage = userMessage || message;
  }

  /**
   * Check if error is a client error (4xx)
   */
  isClientError(): boolean {
    return this.statusCode >= 400 && this.statusCode < 500;
  }

  /**
   * Check if error is a server error (5xx)
   */
  isServerError(): boolean {
    return this.statusCode >= 500 && this.statusCode < 600;
  }

  /**
   * Check if error is a network error
   */
  isNetworkError(): boolean {
    return this.statusCode === 0;
  }

  /**
   * Check if error is a timeout error
   */
  isTimeoutError(): boolean {
    return this.statusCode === 408;
  }
}
