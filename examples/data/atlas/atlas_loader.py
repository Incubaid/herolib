#!/usr/bin/env python3
"""
Atlas Collection Loader for Python

Load Atlas collections from .collection.json files created by the V Atlas module.
This allows Python applications to access Atlas data without running V code.
"""

import json
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass, field
from enum import Enum


class FileType(Enum):
    """File type enumeration"""
    FILE = "file"
    IMAGE = "image"


class CollectionErrorCategory(Enum):
    """Error category enumeration matching V implementation"""
    CIRCULAR_INCLUDE = "circular_include"
    MISSING_INCLUDE = "missing_include"
    INCLUDE_SYNTAX_ERROR = "include_syntax_error"
    INVALID_PAGE_REFERENCE = "invalid_page_reference"
    FILE_NOT_FOUND = "file_not_found"
    INVALID_COLLECTION = "invalid_collection"
    GENERAL_ERROR = "general_error"


@dataclass
class CollectionError:
    """Collection error matching V CollectionError struct"""
    category: str
    page_key: str = ""
    message: str = ""
    file: str = ""

    @classmethod
    def from_dict(cls, data: dict) -> 'CollectionError':
        """Create from dictionary"""
        return cls(
            category=data.get('category', ''),
            page_key=data.get('page_key', ''),
            message=data.get('message', ''),
            file=data.get('file', '')
        )

    def __str__(self) -> str:
        """Human-readable error message"""
        location = ""
        if self.page_key:
            location = f" [{self.page_key}]"
        elif self.file:
            location = f" [{self.file}]"
        return f"[{self.category}]{location}: {self.message}"


@dataclass
class File:
    """File metadata matching V File struct"""
    name: str
    ext: str
    path: str
    ftype: str

    @classmethod
    def from_dict(cls, data: dict) -> 'File':
        """Create from dictionary"""
        return cls(
            name=data['name'],
            ext=data['ext'],
            path=data['path'],
            ftype=data['ftype']
        )

    @property
    def file_type(self) -> FileType:
        """Get file type as enum"""
        return FileType(self.ftype)

    @property
    def file_name(self) -> str:
        """Get full filename with extension"""
        return f"{self.name}.{self.ext}"

    def is_image(self) -> bool:
        """Check if file is an image"""
        return self.file_type == FileType.IMAGE

    def read(self) -> bytes:
        """Read file content as bytes"""
        return Path(self.path).read_bytes()


@dataclass
class Page:
    """Page metadata matching V Page struct"""
    name: str
    path: str
    collection_name: str

    @classmethod
    def from_dict(cls, data: dict) -> 'Page':
        """Create from dictionary"""
        return cls(
            name=data['name'],
            path=data['path'],
            collection_name=data['collection_name']
        )

    def key(self) -> str:
        """Get page key in format 'collection:page'"""
        return f"{self.collection_name}:{self.name}"

    def read_content(self) -> str:
        """Read page content from file"""
        return Path(self.path).read_text(encoding='utf-8')


@dataclass
class Collection:
    """Collection matching V Collection struct"""
    name: str
    path: str
    pages: Dict[str, Page] = field(default_factory=dict)
    images: Dict[str, File] = field(default_factory=dict)
    files: Dict[str, File] = field(default_factory=dict)
    errors: List[CollectionError] = field(default_factory=list)

    def page_get(self, name: str) -> Optional[Page]:
        """Get a page by name"""
        return self.pages.get(name)

    def page_exists(self, name: str) -> bool:
        """Check if page exists"""
        return name in self.pages

    def image_get(self, name: str) -> Optional[File]:
        """Get an image by name"""
        return self.images.get(name)

    def image_exists(self, name: str) -> bool:
        """Check if image exists"""
        return name in self.images

    def file_get(self, name: str) -> Optional[File]:
        """Get a file by name"""
        return self.files.get(name)

    def file_exists(self, name: str) -> bool:
        """Check if file exists"""
        return name in self.files

    def has_errors(self) -> bool:
        """Check if collection has errors"""
        return len(self.errors) > 0

    def error_summary(self) -> Dict[str, int]:
        """Get error count by category"""
        summary = {}
        for err in self.errors:
            category = err.category
            summary[category] = summary.get(category, 0) + 1
        return summary

    def print_errors(self):
        """Print all errors to console"""
        if not self.has_errors():
            print(f"Collection {self.name}: No errors")
            return

        print(f"\nCollection {self.name} - Errors ({len(self.errors)})")
        print("=" * 60)
        for err in self.errors:
            print(f"  {err}")

    @classmethod
    def from_json(cls, json_path: Path) -> 'Collection':
        """
        Load collection from .collection.json file
        
        Args:
            json_path: Path to .collection.json file
            
        Returns:
            Collection instance
        """
        with open(json_path, 'r', encoding='utf-8') as f:
            data = json.load(f)

        # Parse pages - V outputs as map[string]Page
        pages = {}
        for name, page_data in data.get('pages', {}).items():
            pages[name] = Page.from_dict(page_data)

        # Parse images - V outputs as map[string]File
        images = {}
        for name, file_data in data.get('images', {}).items():
            images[name] = File.from_dict(file_data)

        # Parse files - V outputs as map[string]File
        files = {}
        for name, file_data in data.get('files', {}).items():
            files[name] = File.from_dict(file_data)

        # Parse errors - V outputs as []CollectionError
        errors = []
        for err_data in data.get('errors', []):
            errors.append(CollectionError.from_dict(err_data))

        return cls(
            name=data['name'],
            path=data['path'],
            pages=pages,
            images=images,
            files=files,
            errors=errors
        )


@dataclass
class Atlas:
    """Atlas matching V Atlas struct"""
    name: str = "default"
    collections: Dict[str, Collection] = field(default_factory=dict)

    def add_collection(self, collection: Collection):
        """Add a collection to the atlas"""
        self.collections[collection.name] = collection

    def get_collection(self, name: str) -> Optional[Collection]:
        """Get a collection by name"""
        return self.collections.get(name)

    def collection_exists(self, name: str) -> bool:
        """Check if collection exists"""
        return name in self.collections

    def page_get(self, key: str) -> Optional[Page]:
        """
        Get a page using format 'collection:page'
        
        Args:
            key: Page key in format 'collection:page'
            
        Returns:
            Page or None if not found
        """
        parts = key.split(':', 1)
        if len(parts) != 2:
            return None

        col = self.get_collection(parts[0])
        if not col:
            return None

        return col.page_get(parts[1])

    def page_exists(self, key: str) -> bool:
        """Check if page exists using format 'collection:page'"""
        return self.page_get(key) is not None

    def image_get(self, key: str) -> Optional[File]:
        """Get an image using format 'collection:image'"""
        parts = key.split(':', 1)
        if len(parts) != 2:
            return None

        col = self.get_collection(parts[0])
        if not col:
            return None

        return col.image_get(parts[1])

    def image_exists(self, key: str) -> bool:
        """Check if image exists using format 'collection:image'"""
        return self.image_get(key) is not None

    def file_get(self, key: str) -> Optional[File]:
        """Get a file using format 'collection:file'"""
        parts = key.split(':', 1)
        if len(parts) != 2:
            return None

        col = self.get_collection(parts[0])
        if not col:
            return None

        return col.file_get(parts[1])

    def list_collections(self) -> List[str]:
        """List all collection names"""
        return sorted(self.collections.keys())

    def list_pages(self) -> Dict[str, List[str]]:
        """List all pages grouped by collection"""
        result = {}
        for col_name, col in self.collections.items():
            result[col_name] = sorted(col.pages.keys())
        return result

    def has_errors(self) -> bool:
        """Check if any collection has errors"""
        return any(col.has_errors() for col in self.collections.values())

    def print_all_errors(self):
        """Print errors from all collections"""
        for col in self.collections.values():
            if col.has_errors():
                col.print_errors()

    @classmethod
    def load_collection(cls, path: str, name: str = "default") -> 'Atlas':
        """
        Load a single collection from a path.
        
        Args:
            path: Path to the collection directory containing .collection.json
            name: Name for the atlas instance
            
        Returns:
            Atlas with the loaded collection
            
        Example:
            atlas = Atlas.load_collection('/path/to/my_collection')
            col = atlas.get_collection('my_collection')
        """
        atlas = cls(name=name)
        collection_path = Path(path) / '.collection.json'
        
        if not collection_path.exists():
            raise FileNotFoundError(
                f"No .collection.json found at {path}\n"
                f"Make sure to run collection.save() in V first"
            )
        
        collection = Collection.from_json(collection_path)
        atlas.add_collection(collection)
        
        return atlas

    @classmethod
    def load_from_directory(cls, path: str, name: str = "default") -> 'Atlas':
        """
        Walk directory tree and load all collections.
        
        Args:
            path: Root path to scan for .collection.json files
            name: Name for the atlas instance
            
        Returns:
            Atlas with all found collections
            
        Example:
            atlas = Atlas.load_from_directory('/path/to/docs')
            print(f"Loaded {len(atlas.collections)} collections")
        """
        atlas = cls(name=name)
        root = Path(path)
        
        if not root.exists():
            raise FileNotFoundError(f"Path not found: {path}")
        
        # Walk directory tree looking for .collection.json files
        for json_file in root.rglob('.collection.json'):
            try:
                collection = Collection.from_json(json_file)
                atlas.add_collection(collection)
            except Exception as e:
                print(f"Warning: Failed to load {json_file}: {e}")
        
        if len(atlas.collections) == 0:
            print(f"Warning: No collections found in {path}")
        
        return atlas


# ============================================================================
# Example Usage Functions
# ============================================================================

def example_load_single_collection():
    """Example: Load a single collection"""
    print("\n" + "="*60)
    print("Example 1: Load Single Collection")
    print("="*60)
    
    atlas = Atlas.load_collection(
        path='/tmp/atlas_test/col1',
        name='my_atlas'
    )
    
    # Get collection
    col = atlas.get_collection('col1')
    if col:
        print(f"\nLoaded collection: {col.name}")
        print(f"  Path: {col.path}")
        print(f"  Pages: {len(col.pages)}")
        print(f"  Images: {len(col.images)}")
        print(f"  Files: {len(col.files)}")
        
        # Print errors if any
        if col.has_errors():
            col.print_errors()


def example_load_all_collections():
    """Example: Load all collections from a directory tree"""
    print("\n" + "="*60)
    print("Example 2: Load All Collections")
    print("="*60)
    
    atlas = Atlas.load_from_directory(
        path='/tmp/atlas_test',
        name='docs_atlas'
    )
    
    print(f"\nLoaded {len(atlas.collections)} collections:")
    
    # List all collections
    for col_name in atlas.list_collections():
        col = atlas.get_collection(col_name)
        print(f"\n  Collection: {col_name}")
        print(f"    Path: {col.path}")
        print(f"    Pages: {len(col.pages)}")
        print(f"    Images: {len(col.images)}")
        print(f"    Errors: {len(col.errors)}")


def example_access_pages():
    """Example: Access pages and content"""
    print("\n" + "="*60)
    print("Example 3: Access Pages and Content")
    print("="*60)
    
    atlas = Atlas.load_from_directory('/tmp/atlas_test')
    
    # Get a specific page
    page = atlas.page_get('col1:page1')
    if page:
        print(f"\nPage: {page.name}")
        print(f"  Key: {page.key()}")
        print(f"  Path: {page.path}")
        
        # Read content
        content = page.read_content()
        print(f"  Content length: {len(content)} chars")
        print(f"  First 100 chars: {content[:100]}")
    
    # List all pages
    print("\nAll pages:")
    pages = atlas.list_pages()
    for col_name, page_names in pages.items():
        print(f"\n  {col_name}:")
        for page_name in page_names:
            print(f"    - {page_name}")


def example_error_handling():
    """Example: Working with errors"""
    print("\n" + "="*60)
    print("Example 4: Error Handling")
    print("="*60)
    
    atlas = Atlas.load_from_directory('/tmp/atlas_test')
    
    # Check for errors across all collections
    if atlas.has_errors():
        print("\nFound errors in collections:")
        atlas.print_all_errors()
    else:
        print("\nNo errors found!")
    
    # Get error summary for a specific collection
    col = atlas.get_collection('col1')
    if col and col.has_errors():
        summary = col.error_summary()
        print(f"\nError summary for {col.name}:")
        for category, count in summary.items():
            print(f"  {category}: {count}")


if __name__ == '__main__':
    print("Atlas Loader - Python Implementation")
    print("="*60)
    print("\nThis script demonstrates loading Atlas collections")
    print("from .collection.json files created by the V Atlas module.")
    
    # Uncomment to run examples:
    # example_load_single_collection()
    # example_load_all_collections()
    # example_access_pages()
    # example_error_handling()
    
    print("\nUncomment example functions in __main__ to see them in action.")