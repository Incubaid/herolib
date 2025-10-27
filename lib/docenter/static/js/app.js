/**
 * Main Application
 * Coordinates all modules and handles user interactions
 */

// Global state
let webdavClient;
let fileTree;
let editor;
let darkMode;
let collectionSelector;
let clipboard = null;
let currentFilePath = null;

// Event bus is now loaded from event-bus.js module
// No need to define it here - it's available as window.eventBus

/**
 * Auto-load page in view mode
 * Tries to load the last viewed page, falls back to first file if none saved
 */
async function autoLoadPageInViewMode() {
    if (!editor || !fileTree) return;

    try {
        // Try to get last viewed page
        let pageToLoad = editor.getLastViewedPage();

        // If no last viewed page, get the first markdown file
        if (!pageToLoad) {
            pageToLoad = fileTree.getFirstMarkdownFile();
        }

        // If we found a page to load, load it
        if (pageToLoad) {
            // Use fileTree.onFileSelect to handle both text and binary files
            if (fileTree.onFileSelect) {
                fileTree.onFileSelect({ path: pageToLoad, isDirectory: false });
            } else {
                // Fallback to direct loading (for text files only)
                await editor.loadFile(pageToLoad);
                fileTree.selectAndExpandPath(pageToLoad);
            }
        } else {
            // No files found, show empty state message
            editor.previewElement.innerHTML = `
                <div class="text-muted text-center mt-5">
                    <p>No content available</p>
                </div>
            `;
        }
    } catch (error) {
        console.error('Failed to auto-load page in view mode:', error);
        editor.previewElement.innerHTML = `
            <div class="alert alert-danger">
                <p>Failed to load content</p>
            </div>
        `;
    }
}

/**
 * Show directory preview with list of files
 * @param {string} dirPath - The directory path
 */
async function showDirectoryPreview(dirPath) {
    if (!editor || !fileTree || !webdavClient) return;

    try {
        const dirName = dirPath.split('/').pop() || dirPath;
        const files = fileTree.getDirectoryFiles(dirPath);

        // Start building the preview HTML
        let html = `<div class="directory-preview">`;
        html += `<h2>${dirName}</h2>`;

        if (files.length === 0) {
            html += `<p>This directory is empty</p>`;
        } else {
            html += `<div class="directory-files">`;

            // Create cards for each file
            for (const file of files) {
                const fileName = file.name;
                let fileDescription = '';

                // Try to get file description from markdown files
                if (file.name.endsWith('.md')) {
                    try {
                        const content = await webdavClient.get(file.path);
                        // Extract first heading or first line as description
                        const lines = content.split('\n');
                        for (const line of lines) {
                            if (line.trim().startsWith('#')) {
                                fileDescription = line.replace(/^#+\s*/, '').trim();
                                break;
                            } else if (line.trim() && !line.startsWith('---')) {
                                fileDescription = line.trim().substring(0, 100);
                                break;
                            }
                        }
                    } catch (error) {
                        console.error('Failed to read file description:', error);
                    }
                }

                html += `
                    <div class="file-card" data-path="${file.path}">
                        <div class="file-card-header">
                            <i class="bi bi-file-earmark-text"></i>
                            <span class="file-card-name">${fileName}</span>
                        </div>
                        ${fileDescription ? `<div class="file-card-description">${fileDescription}</div>` : ''}
                    </div>
                `;
            }

            html += `</div>`;
        }

        html += `</div>`;

        // Set the preview content
        editor.previewElement.innerHTML = html;

        // Add click handlers to file cards
        editor.previewElement.querySelectorAll('.file-card').forEach(card => {
            card.addEventListener('click', async () => {
                const filePath = card.dataset.path;
                await editor.loadFile(filePath);
                fileTree.selectAndExpandPath(filePath);
            });
        });
    } catch (error) {
        console.error('Failed to show directory preview:', error);
        editor.previewElement.innerHTML = `
            <div class="alert alert-danger">
                <p>Failed to load directory preview</p>
            </div>
        `;
    }
}

/**
 * Parse URL to extract collection and file path
 * URL format: /<collection>/<file_path> or /<collection>/<dir>/<file>
 * @returns {Object} {collection, filePath} or {collection, null} if only collection
 */
function parseURLPath() {
    const pathname = window.location.pathname;
    const parts = pathname.split('/').filter(p => p); // Remove empty parts

    if (parts.length === 0) {
        return { collection: null, filePath: null };
    }

    const collection = parts[0];
    const filePath = parts.length > 1 ? parts.slice(1).join('/') : null;

    return { collection, filePath };
}

/**
 * Update URL based on current collection and file
 * @param {string} collection - The collection name
 * @param {string} filePath - The file path (optional)
 * @param {boolean} isEditMode - Whether in edit mode
 */
function updateURL(collection, filePath, isEditMode) {
    let url = `/${collection}`;
    if (filePath) {
        url += `/${filePath}`;
    }
    if (isEditMode) {
        url += '?edit=true';
    }

    // Use pushState to update URL without reloading
    window.history.pushState({ collection, filePath }, '', url);
}

/**
 * Load file from URL path
 * Assumes the collection is already set and file tree is loaded
 * @param {string} collection - The collection name (for validation)
 * @param {string} filePath - The file path
 */
async function loadFileFromURL(collection, filePath) {
    console.log('[loadFileFromURL] Called with:', { collection, filePath });

    if (!fileTree || !editor || !collectionSelector) {
        console.error('[loadFileFromURL] Missing dependencies:', { fileTree: !!fileTree, editor: !!editor, collectionSelector: !!collectionSelector });
        return;
    }

    try {
        // Verify we're on the right collection
        const currentCollection = collectionSelector.getCurrentCollection();
        if (currentCollection !== collection) {
            console.error(`[loadFileFromURL] Collection mismatch: expected ${collection}, got ${currentCollection}`);
            return;
        }

        // Load the file or directory
        if (filePath) {
            // Check if the path is a directory or a file
            const node = fileTree.findNode(filePath);
            console.log('[loadFileFromURL] Found node:', node);

            if (node && node.isDirectory) {
                // It's a directory, show directory preview
                console.log('[loadFileFromURL] Loading directory preview');
                await showDirectoryPreview(filePath);
                fileTree.selectAndExpandPath(filePath);
            } else if (node) {
                // It's a file, check if it's binary
                console.log('[loadFileFromURL] Loading file');

                // Use the fileTree.onFileSelect callback to handle both text and binary files
                if (fileTree.onFileSelect) {
                    fileTree.onFileSelect({ path: filePath, isDirectory: false });
                } else {
                    // Fallback to direct loading
                    await editor.loadFile(filePath);
                    fileTree.selectAndExpandPath(filePath);
                }
            } else {
                console.error(`[loadFileFromURL] Path not found in file tree: ${filePath}`);
            }
        }
    } catch (error) {
        console.error('[loadFileFromURL] Failed to load file from URL:', error);
    }
}

/**
 * Handle browser back/forward navigation
 */
function setupPopStateListener() {
    window.addEventListener('popstate', async (event) => {
        const { collection, filePath } = parseURLPath();
        if (collection) {
            // Ensure the collection is set
            const currentCollection = collectionSelector.getCurrentCollection();
            if (currentCollection !== collection) {
                await collectionSelector.setCollection(collection);
                await fileTree.load();
            }

            // Load the file/directory
            await loadFileFromURL(collection, filePath);
        }
    });
}

// Initialize application
document.addEventListener('DOMContentLoaded', async () => {
    // Determine view mode from URL parameter
    const urlParams = new URLSearchParams(window.location.search);
    const isEditMode = urlParams.get('edit') === 'true';

    // Set view mode class on body
    if (isEditMode) {
        document.body.classList.add('edit-mode');
        document.body.classList.remove('view-mode');
    } else {
        document.body.classList.add('view-mode');
        document.body.classList.remove('edit-mode');
    }

    // Initialize WebDAV client
    // Use relative path since UI and WebDAV are on the same server
    webdavClient = new WebDAVClient(Config.WEBDAV_BASE_URL);

    // Initialize dark mode
    darkMode = new DarkMode();
    document.getElementById('darkModeBtn').addEventListener('click', () => {
        darkMode.toggle();
    });

    // Initialize sidebar toggle
    const sidebarToggle = new SidebarToggle('sidebarPane', 'sidebarToggleBtn');

    // Initialize collection selector (always needed)
    collectionSelector = new CollectionSelector('collectionSelect', webdavClient);
    await collectionSelector.load();

    // Setup New Collection button
    document.getElementById('newCollectionBtn').addEventListener('click', async () => {
        try {
            const collectionName = await window.ModalManager.prompt(
                'Enter new collection name (lowercase, underscore only):',
                'new_collection'
            );

            if (!collectionName) return;

            // Validate collection name
            const validation = ValidationUtils.validateFileName(collectionName, true);
            if (!validation.valid) {
                window.showNotification(validation.message, 'warning');
                return;
            }

            // Create the collection
            await webdavClient.createCollection(validation.sanitized);

            // Reload collections and switch to the new one
            await collectionSelector.load();
            await collectionSelector.setCollection(validation.sanitized);

            // Reload the file tree to show the new empty collection
            if (fileTree) {
                await fileTree.load();
            }

            window.showNotification(`Collection "${validation.sanitized}" created`, 'success');
        } catch (error) {
            Logger.error('Failed to create collection:', error);
            window.showNotification('Failed to create collection', 'error');
        }
    });

    // Setup URL routing
    setupPopStateListener();

    // Initialize editor (always needed for preview)
    // In view mode, editor is read-only
    editor = new MarkdownEditor('editor', 'preview', 'filenameInput', !isEditMode);
    editor.setWebDAVClient(webdavClient);

    // Initialize file tree (needed in both modes)
    // Pass isEditMode to control image filtering (hide images only in view mode)
    fileTree = new FileTree('fileTree', webdavClient, isEditMode);
    fileTree.onFileSelect = async (item) => {
        try {
            const currentCollection = collectionSelector.getCurrentCollection();

            // Check if the file is a binary/non-editable file
            if (PathUtils.isBinaryFile(item.path)) {
                const fileType = PathUtils.getFileType(item.path);
                const fileName = PathUtils.getFileName(item.path);

                Logger.info(`Previewing binary file: ${item.path}`);

                // Initialize and show loading spinner for binary file preview
                editor.initLoadingSpinners();
                if (editor.previewSpinner) {
                    editor.previewSpinner.show(`Loading ${fileType.toLowerCase()}...`);
                }

                // Set flag to prevent auto-update of preview
                editor.isShowingCustomPreview = true;

                // In edit mode, show a warning notification
                if (isEditMode) {
                    if (window.showNotification) {
                        window.showNotification(
                            `"${fileName}" is read-only. Showing preview only.`,
                            'warning'
                        );
                    }

                    // Hide the editor pane temporarily
                    const editorPane = document.getElementById('editorPane');
                    const resizer1 = document.getElementById('resizer1');
                    if (editorPane) editorPane.style.display = 'none';
                    if (resizer1) resizer1.style.display = 'none';
                }

                // Clear the editor (but don't trigger preview update due to flag)
                if (editor.editor) {
                    editor.editor.setValue('');
                }
                editor.filenameInput.value = item.path;
                editor.currentFile = item.path;

                // Build the file URL using the WebDAV client's method
                const fileUrl = webdavClient.getFullUrl(item.path);
                Logger.debug(`Binary file URL: ${fileUrl}`);

                // Generate preview HTML based on file type
                let previewHtml = '';

                if (fileType === 'Image') {
                    // Preview images
                    previewHtml = `
                        <div style="padding: 20px; text-align: center;">
                            <h3>${fileName}</h3>
                            <p style="color: var(--text-secondary); margin-bottom: 20px;">Image Preview (Read-only)</p>
                            <img src="${fileUrl}" alt="${fileName}" style="max-width: 100%; height: auto; border: 1px solid var(--border-color); border-radius: 4px;">
                        </div>
                    `;
                } else if (fileType === 'PDF') {
                    // Preview PDFs
                    previewHtml = `
                        <div style="padding: 20px;">
                            <h3>${fileName}</h3>
                            <p style="color: var(--text-secondary); margin-bottom: 20px;">PDF Preview (Read-only)</p>
                            <iframe src="${fileUrl}" style="width: 100%; height: 80vh; border: 1px solid var(--border-color); border-radius: 4px;"></iframe>
                        </div>
                    `;
                } else {
                    // For other binary files, show download link
                    previewHtml = `
                        <div style="padding: 20px;">
                            <h3>${fileName}</h3>
                            <p style="color: var(--text-secondary); margin-bottom: 20px;">${fileType} File (Read-only)</p>
                            <p>This file cannot be previewed in the browser.</p>
                            <a href="${fileUrl}" download="${fileName}" class="btn btn-primary">Download ${fileName}</a>
                        </div>
                    `;
                }

                // Display in preview pane
                editor.previewElement.innerHTML = previewHtml;

                // Hide loading spinner after content is set
                // Add small delay for images to start loading
                setTimeout(() => {
                    if (editor.previewSpinner) {
                        editor.previewSpinner.hide();
                    }
                }, fileType === 'Image' ? 300 : 100);

                // Highlight the file in the tree
                fileTree.selectAndExpandPath(item.path);

                // Save as last viewed page (for binary files too)
                editor.saveLastViewedPage(item.path);

                // Update URL to reflect current file
                updateURL(currentCollection, item.path, isEditMode);

                return;
            }

            // For text files, restore the editor pane if it was hidden
            if (isEditMode) {
                const editorPane = document.getElementById('editorPane');
                const resizer1 = document.getElementById('resizer1');
                if (editorPane) editorPane.style.display = '';
                if (resizer1) resizer1.style.display = '';
            }

            await editor.loadFile(item.path);
            // Highlight the file in the tree and expand parent directories
            fileTree.selectAndExpandPath(item.path);
            // Update URL to reflect current file
            updateURL(currentCollection, item.path, isEditMode);
        } catch (error) {
            Logger.error('Failed to select file:', error);
            if (window.showNotification) {
                window.showNotification('Failed to load file', 'error');
            }
        }
    };

    fileTree.onFolderSelect = async (item) => {
        try {
            // Show directory preview
            await showDirectoryPreview(item.path);
            // Highlight the directory in the tree and expand parent directories
            fileTree.selectAndExpandPath(item.path);
            // Update URL to reflect current directory
            const currentCollection = collectionSelector.getCurrentCollection();
            updateURL(currentCollection, item.path, isEditMode);
        } catch (error) {
            Logger.error('Failed to select folder:', error);
            if (window.showNotification) {
                window.showNotification('Failed to load folder', 'error');
            }
        }
    };

    collectionSelector.onChange = async (collection) => {
        try {
            await fileTree.load();
            // In view mode, auto-load last viewed page when collection changes
            if (!isEditMode) {
                await autoLoadPageInViewMode();
            }
        } catch (error) {
            Logger.error('Failed to change collection:', error);
            if (window.showNotification) {
                window.showNotification('Failed to change collection', 'error');
            }
        }
    };
    await fileTree.load();

    // Parse URL to load file if specified
    const { collection: urlCollection, filePath: urlFilePath } = parseURLPath();
    console.log('[URL PARSE]', { urlCollection, urlFilePath });

    if (urlCollection) {
        // First ensure the collection is set
        const currentCollection = collectionSelector.getCurrentCollection();
        if (currentCollection !== urlCollection) {
            console.log('[URL LOAD] Switching collection from', currentCollection, 'to', urlCollection);
            await collectionSelector.setCollection(urlCollection);
            await fileTree.load();
        }

        // If there's a file path in the URL, load it
        if (urlFilePath) {
            console.log('[URL LOAD] Loading file from URL:', urlCollection, urlFilePath);
            await loadFileFromURL(urlCollection, urlFilePath);
        } else if (!isEditMode) {
            // Collection-only URL in view mode: auto-load last viewed page
            console.log('[URL LOAD] Collection-only URL, auto-loading page');
            await autoLoadPageInViewMode();
        }
    } else if (!isEditMode) {
        // No URL collection specified, in view mode: auto-load last viewed page
        await autoLoadPageInViewMode();
    }

    // Initialize file tree and editor-specific features only in edit mode
    if (isEditMode) {
        // Add test content to verify preview works
        setTimeout(() => {
            if (!editor.editor.getValue()) {
                editor.editor.setValue('# Welcome to Docenter\n\nStart typing to see preview...\n');
                editor.updatePreview();
            }
        }, 200);

        // Setup editor drop handler
        const editorDropHandler = new EditorDropHandler(
            document.querySelector('.editor-container'),
            async (file) => {
                try {
                    await handleEditorFileDrop(file);
                } catch (error) {
                    Logger.error('Failed to handle file drop:', error);
                }
            }
        );

        // Setup button handlers
        document.getElementById('newBtn').addEventListener('click', () => {
            editor.newFile();
        });

        document.getElementById('saveBtn').addEventListener('click', async () => {
            try {
                await editor.save();
            } catch (error) {
                Logger.error('Failed to save file:', error);
                if (window.showNotification) {
                    window.showNotification('Failed to save file', 'error');
                }
            }
        });

        document.getElementById('deleteBtn').addEventListener('click', async () => {
            try {
                await editor.deleteFile();
            } catch (error) {
                Logger.error('Failed to delete file:', error);
                if (window.showNotification) {
                    window.showNotification('Failed to delete file', 'error');
                }
            }
        });

        // Setup context menu handlers
        setupContextMenuHandlers();

        // Initialize file tree actions manager
        window.fileTreeActions = new FileTreeActions(webdavClient, fileTree, editor);

        // Setup Exit Edit Mode button
        document.getElementById('exitEditModeBtn').addEventListener('click', () => {
            // Switch to view mode by removing edit=true from URL
            const url = new URL(window.location.href);
            url.searchParams.delete('edit');
            window.location.href = url.toString();
        });

        // Hide Edit Mode button in edit mode
        document.getElementById('editModeBtn').style.display = 'none';
    } else {
        // In view mode, hide editor buttons
        document.getElementById('newBtn').style.display = 'none';
        document.getElementById('saveBtn').style.display = 'none';
        document.getElementById('deleteBtn').style.display = 'none';
        document.getElementById('exitEditModeBtn').style.display = 'none';

        // Show Edit Mode button in view mode
        document.getElementById('editModeBtn').style.display = 'block';

        // Setup Edit Mode button
        document.getElementById('editModeBtn').addEventListener('click', () => {
            // Switch to edit mode by adding edit=true to URL
            const url = new URL(window.location.href);
            url.searchParams.set('edit', 'true');
            window.location.href = url.toString();
        });

        // Auto-load last viewed page or first file
        await autoLoadPageInViewMode();
    }

    // Setup clickable navbar brand (logo/title)
    const navbarBrand = document.getElementById('navbarBrand');
    if (navbarBrand) {
        navbarBrand.addEventListener('click', (e) => {
            e.preventDefault();
            const currentCollection = collectionSelector ? collectionSelector.getCurrentCollection() : null;
            if (currentCollection) {
                // Navigate to collection root
                window.location.href = `/${currentCollection}/`;
            } else {
                // Navigate to home page
                window.location.href = '/';
            }
        });
    }

    // Initialize mermaid (always needed)
    mermaid.initialize({ startOnLoad: true, theme: darkMode.isDark ? 'dark' : 'default' });
    // Listen for file-saved event to reload file tree
    window.eventBus.on('file-saved', async (path) => {
        try {
            if (fileTree) {
                await fileTree.load();
                fileTree.selectNode(path);
            }
        } catch (error) {
            Logger.error('Failed to reload file tree after save:', error);
        }
    });

    window.eventBus.on('file-deleted', async () => {
        try {
            if (fileTree) {
                await fileTree.load();
            }
        } catch (error) {
            Logger.error('Failed to reload file tree after delete:', error);
        }
    });
});

// Listen for column resize events to refresh editor
window.addEventListener('column-resize', () => {
    if (editor && editor.editor) {
        editor.editor.refresh();
    }
});

/**
 * File Operations
 */

/**
 * Context Menu Handlers
 */
function setupContextMenuHandlers() {
    const menu = document.getElementById('contextMenu');

    menu.addEventListener('click', async (e) => {
        const item = e.target.closest('.context-menu-item');
        if (!item) return;

        const action = item.dataset.action;
        const targetPath = menu.dataset.targetPath;
        const isDir = menu.dataset.targetIsDir === 'true';

        hideContextMenu();

        await window.fileTreeActions.execute(action, targetPath, isDir);
    });
}

// All context actions are now handled by FileTreeActions, so this function is no longer needed.
// async function handleContextAction(action, targetPath, isDir) { ... }

function updatePasteVisibility() {
    const pasteItem = document.getElementById('pasteMenuItem');
    if (pasteItem) {
        pasteItem.style.display = clipboard ? 'block' : 'none';
    }
}

/**
 * Editor File Drop Handler
 */
async function handleEditorFileDrop(file) {
    try {
        // Get current file's directory
        let targetDir = '';
        if (currentFilePath) {
            const parts = currentFilePath.split('/');
            parts.pop(); // Remove filename
            targetDir = parts.join('/');
        }

        // Upload file
        const uploadedPath = await fileTree.uploadFile(targetDir, file);

        // Insert markdown link at cursor
        // Use relative path (without collection name) so the image renderer can resolve it correctly
        const isImage = file.type.startsWith('image/');
        const link = isImage
            ? `![${file.name}](${uploadedPath})`
            : `[${file.name}](${uploadedPath})`;

        editor.insertAtCursor(link);
        showNotification(`Uploaded and inserted link`, 'success');
    } catch (error) {
        console.error('Failed to handle file drop:', error);
        showNotification('Failed to upload file', 'error');
    }
}

// Make showContextMenu global
window.showContextMenu = showContextMenu;

