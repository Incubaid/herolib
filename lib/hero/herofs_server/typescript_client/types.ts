/**
 * HeroFS REST API TypeScript Client - Type Definitions
 * 
 * This file contains all TypeScript interfaces and types for the HeroFS REST API.
 * Generated for comprehensive coverage of 50+ endpoints with proper type safety.
 */

// =============================================================================
// COMMON TYPES
// =============================================================================

export interface APIResponse<T = any> {
  success: boolean;
  data: T;
  message: string;
  error: string;
}

export interface ErrorResponse {
  success: boolean;
  error: string;
  message: string;
}

export interface BaseEntity {
  id?: number;
  name?: string;
  description?: string;
  created_at?: number;
  updated_at?: number;
  securitypolicy?: number;
  tags?: number[];
  messages?: any[];
}

// =============================================================================
// FILESYSTEM TYPES
// =============================================================================

export interface Filesystem extends BaseEntity {
  group_id?: number;
  root_dir_id?: number;
  quota_bytes?: number;
  used_bytes?: number;
}

export interface FilesystemCreateRequest {
  name: string;
  description?: string;
  group_id?: number;
  root_dir_id?: number;
  quota_bytes?: number;
  used_bytes?: number;
  tags?: string[];
  messages?: any[];
}

export interface FilesystemUpdateRequest extends FilesystemCreateRequest {
  id: number;
}

export interface UsageRequest {
  bytes: number;
}

export interface QuotaCheckRequest {
  bytes: number;
}

// =============================================================================
// DIRECTORY TYPES
// =============================================================================

export interface Directory extends BaseEntity {
  fs_id: number;
  parent_id?: number;
  directories?: number[];
  files?: number[];
  symlinks?: number[];
}

export interface DirectoryCreateRequest {
  name: string;
  description?: string;
  fs_id: number;
  parent_id?: number;
  tags?: string[];
  messages?: any[];
  directories?: number[];
  files?: number[];
  symlinks?: number[];
}

export interface DirectoryUpdateRequest extends DirectoryCreateRequest {
  id: number;
}

export interface DirectoryPathRequest {
  fs_id: string;
  path: string;
}

// =============================================================================
// FILE TYPES
// =============================================================================

export enum MimeType {
  TEXT = 'text',
  HTML = 'html',
  CSS = 'css',
  JAVASCRIPT = 'javascript',
  JSON = 'json',
  XML = 'xml',
  PDF = 'pdf',
  PNG = 'png',
  JPEG = 'jpeg',
  GIF = 'gif',
  SVG = 'svg',
  MP4 = 'mp4',
  MP3 = 'mp3',
  ZIP = 'zip',
  BINARY = 'binary'
}

export interface File extends BaseEntity {
  fs_id: number;
  directories?: number[];
  blobs?: number[];
  size_bytes?: number;
  mime_type?: MimeType;
  checksum?: string;
  accessed_at?: number;
  metadata?: Record<string, string>;
}

export interface FileCreateRequest {
  name: string;
  description?: string;
  fs_id: number;
  directories?: number[];
  blobs?: number[];
  size_bytes?: number;
  mime_type?: MimeType;
  checksum?: string;
  accessed_at?: number;
  metadata?: Record<string, string>;
  tags?: string[];
  messages?: any[];
}

export interface FileUpdateRequest extends FileCreateRequest {
  id: number;
}

export interface FileDirectoryRequest {
  dir_id: number;
}

export interface FileMetadataRequest {
  key: string;
  value: string;
}

// =============================================================================
// BLOB TYPES
// =============================================================================

export interface Blob extends BaseEntity {
  hash?: string;
  data?: number[];
  size_bytes?: number;
  created_at?: number;
  mime_type?: string;
  encoding?: string;
}

export interface BlobCreateRequest {
  name?: string;
  description?: string;
  data: number[];
  mime_type?: string;
  encoding?: string;
  created_at?: number;
  tags?: string[];
  messages?: any[];
}

export interface BlobUpdateRequest extends BlobCreateRequest {
  id: number;
}

// =============================================================================
// BLOB MEMBERSHIP TYPES
// =============================================================================

export interface BlobMembership {
  hash: string;
  fsid: number[];
  blobid: number;
}

export interface BlobMembershipCreateRequest {
  hash?: string;
  fsid: number[];
  blobid: number;
}

// =============================================================================
// SYMLINK TYPES
// =============================================================================

export enum SymlinkTargetType {
  FILE = 'file',
  DIRECTORY = 'directory'
}

export interface Symlink extends BaseEntity {
  fs_id: number;
  parent_id: number;
  target_id: number;
  target_type: SymlinkTargetType;
}

export interface SymlinkCreateRequest {
  name: string;
  description?: string;
  fs_id: number;
  parent_id: number;
  target_id: number;
  target_type: SymlinkTargetType;
  tags?: string[];
  messages?: any[];
}

export interface SymlinkUpdateRequest extends SymlinkCreateRequest {
  id: number;
}

// =============================================================================
// TOOLS TYPES
// =============================================================================

export interface ToolsListRequest {
  fs_id: number;
  path: string;
}

export interface ToolsFindRequest {
  fs_id: number;
  pattern: string;
  path: string;
}

export interface ToolsCopyRequest {
  fs_id: number;
  source_path: string;
  dest_path: string;
}

export interface ToolsMoveRequest {
  fs_id: number;
  source_path: string;
  dest_path: string;
}

export interface ToolsRemoveRequest {
  fs_id: number;
  path: string;
}

export interface ToolsImportFileRequest {
  fs_id: number;
  real_path: string;
  vfs_path: string;
  overwrite: string;
}

export interface ToolsImportDirectoryRequest {
  fs_id: number;
  real_path: string;
  vfs_path: string;
  overwrite: string;
}

export interface ToolsExportFileRequest {
  fs_id: number;
  vfs_path: string;
  real_path: string;
  overwrite: string;
}

export interface ToolsExportDirectoryRequest {
  fs_id: number;
  vfs_path: string;
  real_path: string;
  overwrite: string;
}

export interface ToolsContentRequest {
  path: string;
}

// =============================================================================
// API INFO TYPES
// =============================================================================

export interface APIInfo {
  info: {
    name: string;
    version: string;
    description: string;
  };
  endpoints: {
    filesystems: string;
    directories: string;
    files: string;
    blobs: string;
    symlinks: string;
    blob_membership: string;
    tools: string;
  };
}

// =============================================================================
// CLIENT CONFIGURATION TYPES
// =============================================================================

export interface HeroFSClientConfig {
  baseUrl?: string;
  timeout?: number;
  headers?: Record<string, string>;
  corsEnabled?: boolean;
}

export interface RequestOptions {
  timeout?: number;
  headers?: Record<string, string>;
}
