/**
 * WebDAV Client
 * Handles all WebDAV protocol operations
 */

class WebDAVClient {
    constructor(baseUrl, username = 'admin', password = '123') {
        this.baseUrl = baseUrl;
        this.currentCollection = null;
        this.username = username;
        this.password = password;
    }

    setCollection(collection) {
        this.currentCollection = collection;
    }

    getFullUrl(path) {
        if (!this.currentCollection) {
            throw new Error('No collection selected');
        }
        const cleanPath = path.startsWith('/') ? path.slice(1) : path;
        return `${this.baseUrl}${this.currentCollection}/${cleanPath}`;
    }

    getAuthHeaders() {
        // Create Basic Authentication header
        const credentials = btoa(`${this.username}:${this.password}`);
        return {
            'Authorization': `Basic ${credentials}`
        };
    }

    async getCollections() {
        // Use PROPFIND to list directories under /fs/
        const response = await fetch(this.baseUrl, {
            method: 'PROPFIND',
            headers: {
                'Depth': '1',
                'Content-Type': 'application/xml',
                ...this.getAuthHeaders()
            }
        });

        if (!response.ok) {
            throw new Error('Failed to get collections');
        }

        // Parse the XML response
        const xmlText = await response.text();
        const parser = new DOMParser();
        const xmlDoc = parser.parseFromString(xmlText, 'text/xml');

        // Extract collection names from the response
        const collections = [];
        const responses = xmlDoc.getElementsByTagNameNS('DAV:', 'response');

        for (let i = 0; i < responses.length; i++) {
            const href = responses[i].getElementsByTagNameNS('DAV:', 'href')[0]?.textContent;
            const resourcetype = responses[i].getElementsByTagNameNS('DAV:', 'resourcetype')[0];
            const isCollection = resourcetype?.getElementsByTagNameNS('DAV:', 'collection').length > 0;

            if (href && isCollection && href !== this.baseUrl && href !== this.baseUrl + '/') {
                // Extract collection name from href (e.g., "/fs/notes/" -> "notes")
                const collectionName = href.replace(this.baseUrl, '').replace(/\//g, '');
                if (collectionName) {
                    collections.push(collectionName);
                }
            }
        }

        return collections;
    }

    async createCollection(collectionName) {
        // Use MKCOL to create collection directory
        const url = `${this.baseUrl}${collectionName}/`;
        const response = await fetch(url, {
            method: 'MKCOL',
            headers: this.getAuthHeaders()
        });

        if (!response.ok && response.status !== 405) { // 405 means already exists
            throw new Error(`Failed to create collection: ${response.status} ${response.statusText}`);
        }

        return true;
    }

    async propfind(path = '', depth = '1') {
        const url = this.getFullUrl(path);
        const response = await fetch(url, {
            method: 'PROPFIND',
            headers: {
                'Depth': depth,
                'Content-Type': 'application/xml',
                ...this.getAuthHeaders()
            }
        });

        if (!response.ok) {
            throw new Error(`PROPFIND failed: ${response.statusText}`);
        }

        const xml = await response.text();
        return this.parseMultiStatus(xml);
    }

    /**
     * List files and directories in a path
     * Returns only direct children (depth=1) to avoid infinite recursion
     * @param {string} path - Path to list
     * @param {boolean} recursive - If true, returns all nested items (depth=infinity)
     * @returns {Promise<Array>} Array of items
     */
    async list(path = '', recursive = false) {
        const depth = recursive ? 'infinity' : '1';
        const items = await this.propfind(path, depth);

        // If not recursive, filter to only direct children
        if (!recursive && path) {
            // Normalize path (remove trailing slash)
            const normalizedPath = path.endsWith('/') ? path.slice(0, -1) : path;
            const pathDepth = normalizedPath.split('/').length;

            // Filter items to only include direct children
            return items.filter(item => {
                const itemDepth = item.path.split('/').length;
                return itemDepth === pathDepth + 1;
            });
        }

        return items;
    }

    async get(path) {
        const url = this.getFullUrl(path);
        const response = await fetch(url, {
            headers: this.getAuthHeaders()
        });

        if (!response.ok) {
            throw new Error(`GET failed: ${response.statusText}`);
        }

        return await response.text();
    }

    async getBinary(path) {
        const url = this.getFullUrl(path);
        const response = await fetch(url, {
            headers: this.getAuthHeaders()
        });

        if (!response.ok) {
            throw new Error(`GET failed: ${response.statusText}`);
        }

        return await response.blob();
    }

    async put(path, content) {
        const url = this.getFullUrl(path);
        const response = await fetch(url, {
            method: 'PUT',
            headers: {
                'Content-Type': 'text/plain',
                ...this.getAuthHeaders()
            },
            body: content
        });

        if (!response.ok) {
            throw new Error(`PUT failed: ${response.statusText}`);
        }

        return true;
    }

    async putBinary(path, content) {
        const url = this.getFullUrl(path);
        const response = await fetch(url, {
            method: 'PUT',
            headers: this.getAuthHeaders(),
            body: content
        });

        if (!response.ok) {
            throw new Error(`PUT failed: ${response.statusText}`);
        }

        return true;
    }

    async delete(path) {
        const url = this.getFullUrl(path);
        const response = await fetch(url, {
            method: 'DELETE',
            headers: this.getAuthHeaders()
        });

        if (!response.ok) {
            throw new Error(`DELETE failed: ${response.statusText}`);
        }

        return true;
    }

    async copy(sourcePath, destPath) {
        const sourceUrl = this.getFullUrl(sourcePath);
        const destUrl = this.getFullUrl(destPath);

        const response = await fetch(sourceUrl, {
            method: 'COPY',
            headers: {
                'Destination': destUrl,
                ...this.getAuthHeaders()
            }
        });

        if (!response.ok) {
            throw new Error(`COPY failed: ${response.statusText}`);
        }

        return true;
    }

    async move(sourcePath, destPath) {
        const sourceUrl = this.getFullUrl(sourcePath);
        const destUrl = this.getFullUrl(destPath);

        const response = await fetch(sourceUrl, {
            method: 'MOVE',
            headers: {
                'Destination': destUrl,
                ...this.getAuthHeaders()
            }
        });

        if (!response.ok) {
            throw new Error(`MOVE failed: ${response.statusText}`);
        }

        return true;
    }

    async mkcol(path) {
        const url = this.getFullUrl(path);
        const response = await fetch(url, {
            method: 'MKCOL',
            headers: this.getAuthHeaders()
        });

        if (!response.ok && response.status !== 405) { // 405 means already exists
            throw new Error(`MKCOL failed: ${response.statusText}`);
        }

        return true;
    }

    // Alias for mkcol
    async createFolder(path) {
        return await this.mkcol(path);
    }

    /**
     * Ensure all parent directories exist for a given path
     * Creates missing parent directories recursively
     */
    async ensureParentDirectories(filePath) {
        const parts = filePath.split('/');

        // Remove the filename (last part)
        parts.pop();

        // If no parent directories, nothing to do
        if (parts.length === 0) {
            return;
        }

        // Create each parent directory level
        let currentPath = '';
        for (const part of parts) {
            currentPath = currentPath ? `${currentPath}/${part}` : part;

            try {
                await this.mkcol(currentPath);
            } catch (error) {
                // Ignore errors - directory might already exist
                // Only log for debugging
                console.debug(`Directory ${currentPath} might already exist:`, error.message);
            }
        }
    }

    async includeFile(path) {
        try {
            // Parse path: "collection:path/to/file" or "path/to/file"
            let targetCollection = this.currentCollection;
            let targetPath = path;

            if (path.includes(':')) {
                [targetCollection, targetPath] = path.split(':');
            }

            // Temporarily switch collection
            const originalCollection = this.currentCollection;
            this.currentCollection = targetCollection;

            const content = await this.get(targetPath);

            // Restore collection
            this.currentCollection = originalCollection;

            return content;
        } catch (error) {
            throw new Error(`Cannot include file "${path}": ${error.message}`);
        }
    }

    parseMultiStatus(xml) {
        const parser = new DOMParser();
        const doc = parser.parseFromString(xml, 'text/xml');
        const responses = doc.getElementsByTagNameNS('DAV:', 'response');

        const items = [];
        for (let i = 0; i < responses.length; i++) {
            const response = responses[i];
            const href = response.getElementsByTagNameNS('DAV:', 'href')[0].textContent;
            const propstat = response.getElementsByTagNameNS('DAV:', 'propstat')[0];
            const prop = propstat.getElementsByTagNameNS('DAV:', 'prop')[0];

            // Check if it's a collection (directory)
            const resourcetype = prop.getElementsByTagNameNS('DAV:', 'resourcetype')[0];
            const isDirectory = resourcetype.getElementsByTagNameNS('DAV:', 'collection').length > 0;

            // Get size
            const contentlengthEl = prop.getElementsByTagNameNS('DAV:', 'getcontentlength')[0];
            const size = contentlengthEl ? parseInt(contentlengthEl.textContent) : 0;

            // Extract path relative to collection
            const pathParts = href.split(`/${this.currentCollection}/`);
            const relativePath = pathParts.length > 1 ? pathParts[1] : '';

            // Skip the collection root itself
            if (!relativePath) continue;

            // Remove trailing slash from directories
            const cleanPath = relativePath.endsWith('/') ? relativePath.slice(0, -1) : relativePath;

            items.push({
                path: cleanPath,
                name: cleanPath.split('/').pop(),
                isDirectory,
                size
            });
        }

        return items;
    }

    buildTree(items) {
        const root = [];
        const map = {};

        // Sort items by path depth and name
        items.sort((a, b) => {
            const depthA = a.path.split('/').length;
            const depthB = b.path.split('/').length;
            if (depthA !== depthB) return depthA - depthB;
            return a.path.localeCompare(b.path);
        });

        items.forEach(item => {
            const parts = item.path.split('/');
            const parentPath = parts.slice(0, -1).join('/');

            const node = {
                ...item,
                children: []
            };

            map[item.path] = node;

            if (parentPath && map[parentPath]) {
                map[parentPath].children.push(node);
            } else {
                root.push(node);
            }

        });

        return root;
    }
}

