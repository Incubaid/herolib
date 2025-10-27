/**
 * File Tree Component
 * Manages the hierarchical file tree display and interactions
 */

class FileTree {
    constructor(containerId, webdavClient, isEditMode = false) {
        this.container = document.getElementById(containerId);
        this.webdavClient = webdavClient;
        this.tree = [];
        this.selectedPath = null;
        this.onFileSelect = null;
        this.onFolderSelect = null;
        this.filterImagesInViewMode = !isEditMode; // Track if we should filter images (true in view mode)

        // Drag and drop state
        this.draggedNode = null;
        this.draggedPath = null;
        this.draggedIsDir = false;

        // Long-press detection
        this.longPressTimer = null;
        this.longPressThreshold = Config.LONG_PRESS_THRESHOLD;
        this.isDraggingEnabled = false;
        this.mouseDownNode = null;

        // Undo functionality
        this.lastMoveOperation = null;

        this.setupEventListeners();
        this.setupUndoListener();
    }

    setupEventListeners() {
        // Click handler for tree nodes
        this.container.addEventListener('click', (e) => {
            const node = e.target.closest('.tree-node');
            if (!node) return;

            const path = node.dataset.path;
            const isDir = node.dataset.isdir === 'true';

            // Check if toggle was clicked (icon or toggle button)
            const toggle = e.target.closest('.tree-node-toggle');
            if (toggle) {
                // Toggle is handled by its own click listener in renderNodes
                return;
            }

            // Select node
            if (isDir) {
                this.selectFolder(path);
            } else {
                this.selectFile(path);
            }
        });

        // Context menu (only in edit mode)
        this.container.addEventListener('contextmenu', (e) => {
            // Check if we're in edit mode
            const isEditMode = document.body.classList.contains('edit-mode');

            // In view mode, disable custom context menu entirely
            if (!isEditMode) {
                e.preventDefault(); // Prevent default browser context menu
                return; // Don't show custom context menu
            }

            // Edit mode: show custom context menu
            const node = e.target.closest('.tree-node');
            e.preventDefault();

            if (node) {
                // Clicked on a node
                const path = node.dataset.path;
                const isDir = node.dataset.isdir === 'true';
                window.showContextMenu(e.clientX, e.clientY, { path, isDir });
            } else if (e.target === this.container) {
                // Clicked on the empty space in the file tree container
                window.showContextMenu(e.clientX, e.clientY, { path: '', isDir: true });
            }
        });

        // Drag and drop event listeners (only in edit mode)
        this.setupDragAndDrop();
    }

    setupUndoListener() {
        // Listen for Ctrl+Z (Windows/Linux) or Cmd+Z (Mac)
        document.addEventListener('keydown', async (e) => {
            // Check for Ctrl+Z or Cmd+Z
            const isUndo = (e.ctrlKey || e.metaKey) && e.key === 'z';

            if (isUndo && this.isEditMode() && this.lastMoveOperation) {
                e.preventDefault();
                await this.undoLastMove();
            }
        });
    }

    async undoLastMove() {
        if (!this.lastMoveOperation) {
            return;
        }

        const { sourcePath, destPath, fileName, isDirectory } = this.lastMoveOperation;

        try {
            // Move the item back to its original location
            await this.webdavClient.move(destPath, sourcePath);

            // Get the parent folder name for the notification
            const sourceParent = PathUtils.getParentPath(sourcePath);
            const parentName = sourceParent ? sourceParent + '/' : 'root';

            // Clear the undo history
            this.lastMoveOperation = null;

            // Reload the tree
            await this.load();

            // Re-select the moved item
            this.selectAndExpandPath(sourcePath);

            showNotification(`Undo: Moved ${fileName} back to ${parentName}`, 'success');
        } catch (error) {
            console.error('Failed to undo move:', error);
            showNotification('Failed to undo move: ' + error.message, 'danger');
        }
    }

    setupDragAndDrop() {
        // Dragover event on container to allow dropping on root level
        this.container.addEventListener('dragover', (e) => {
            if (!this.isEditMode() || !this.draggedPath) return;

            const node = e.target.closest('.tree-node');
            if (!node) {
                // Hovering over empty space (root level)
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';

                // Highlight the entire container as a drop target
                this.container.classList.add('drag-over-root');
            }
        });

        // Dragleave event on container to remove root-level highlighting
        this.container.addEventListener('dragleave', (e) => {
            if (!this.isEditMode()) return;

            // Only remove if we're actually leaving the container
            // Check if the related target is outside the container
            if (!this.container.contains(e.relatedTarget)) {
                this.container.classList.remove('drag-over-root');
            }
        });

        // Dragenter event to manage highlighting
        this.container.addEventListener('dragenter', (e) => {
            if (!this.isEditMode() || !this.draggedPath) return;

            const node = e.target.closest('.tree-node');
            if (!node) {
                // Entering empty space
                this.container.classList.add('drag-over-root');
            } else {
                // Entering a node, remove root highlighting
                this.container.classList.remove('drag-over-root');
            }
        });

        // Drop event on container for root level drops
        this.container.addEventListener('drop', async (e) => {
            if (!this.isEditMode()) return;

            const node = e.target.closest('.tree-node');
            if (!node && this.draggedPath) {
                // Dropped on root level
                e.preventDefault();
                this.container.classList.remove('drag-over-root');
                await this.handleDrop('', true);
            }
        });
    }

    isEditMode() {
        return document.body.classList.contains('edit-mode');
    }

    setupNodeDragHandlers(nodeElement, node) {
        // Dragstart - when user starts dragging
        nodeElement.addEventListener('dragstart', (e) => {
            this.draggedNode = nodeElement;
            this.draggedPath = node.path;
            this.draggedIsDir = node.isDirectory;

            nodeElement.classList.add('dragging');
            document.body.classList.add('dragging-active');
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', node.path);

            // Create a custom drag image with fixed width
            const dragImage = nodeElement.cloneNode(true);
            dragImage.style.position = 'absolute';
            dragImage.style.top = '-9999px';
            dragImage.style.left = '-9999px';
            dragImage.style.width = `${Config.DRAG_PREVIEW_WIDTH}px`;
            dragImage.style.maxWidth = `${Config.DRAG_PREVIEW_WIDTH}px`;
            dragImage.style.opacity = Config.DRAG_PREVIEW_OPACITY;
            dragImage.style.backgroundColor = 'var(--bg-secondary)';
            dragImage.style.border = '1px solid var(--border-color)';
            dragImage.style.borderRadius = '4px';
            dragImage.style.padding = '4px 8px';
            dragImage.style.whiteSpace = 'nowrap';
            dragImage.style.overflow = 'hidden';
            dragImage.style.textOverflow = 'ellipsis';

            document.body.appendChild(dragImage);
            e.dataTransfer.setDragImage(dragImage, 10, 10);
            setTimeout(() => {
                if (dragImage.parentNode) {
                    document.body.removeChild(dragImage);
                }
            }, 0);
        });

        // Dragend - when drag operation ends
        nodeElement.addEventListener('dragend', () => {
            nodeElement.classList.remove('dragging');
            nodeElement.classList.remove('drag-ready');
            document.body.classList.remove('dragging-active');
            this.container.classList.remove('drag-over-root');
            this.clearDragOverStates();

            // Reset draggable state
            nodeElement.draggable = false;
            nodeElement.style.cursor = '';
            this.isDraggingEnabled = false;

            this.draggedNode = null;
            this.draggedPath = null;
            this.draggedIsDir = false;
        });

        // Dragover - when dragging over this node
        nodeElement.addEventListener('dragover', (e) => {
            if (!this.draggedPath) return;

            const targetPath = node.path;
            const targetIsDir = node.isDirectory;

            // Only allow dropping on directories
            if (!targetIsDir) {
                e.dataTransfer.dropEffect = 'none';
                return;
            }

            // Check if this is a valid drop target
            if (this.isValidDropTarget(this.draggedPath, this.draggedIsDir, targetPath)) {
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                nodeElement.classList.add('drag-over');
            } else {
                e.dataTransfer.dropEffect = 'none';
            }
        });

        // Dragleave - when drag leaves this node
        nodeElement.addEventListener('dragleave', (e) => {
            // Only remove if we're actually leaving the node (not entering a child)
            if (e.target === nodeElement) {
                nodeElement.classList.remove('drag-over');

                // If leaving a node and not entering another node, might be going to root
                const relatedNode = e.relatedTarget?.closest('.tree-node');
                if (!relatedNode && this.container.contains(e.relatedTarget)) {
                    // Moving to empty space (root area)
                    this.container.classList.add('drag-over-root');
                }
            }
        });

        // Drop - when item is dropped on this node
        nodeElement.addEventListener('drop', async (e) => {
            e.preventDefault();
            e.stopPropagation();

            nodeElement.classList.remove('drag-over');

            if (!this.draggedPath) return;

            const targetPath = node.path;
            const targetIsDir = node.isDirectory;

            if (targetIsDir && this.isValidDropTarget(this.draggedPath, this.draggedIsDir, targetPath)) {
                await this.handleDrop(targetPath, targetIsDir);
            }
        });
    }

    clearDragOverStates() {
        this.container.querySelectorAll('.drag-over').forEach(node => {
            node.classList.remove('drag-over');
        });
    }

    isValidDropTarget(sourcePath, sourceIsDir, targetPath) {
        // Can't drop on itself
        if (sourcePath === targetPath) {
            return false;
        }

        // If dragging a directory, can't drop into its own descendants
        if (sourceIsDir) {
            // Check if target is a descendant of source
            if (targetPath.startsWith(sourcePath + '/')) {
                return false;
            }
        }

        // Can't drop into the same parent directory
        const sourceParent = PathUtils.getParentPath(sourcePath);
        if (sourceParent === targetPath) {
            return false;
        }

        return true;
    }

    async handleDrop(targetPath, targetIsDir) {
        if (!this.draggedPath) return;

        try {
            const sourcePath = this.draggedPath;
            const fileName = PathUtils.getFileName(sourcePath);
            const isDirectory = this.draggedIsDir;

            // Construct destination path
            let destPath;
            if (targetPath === '') {
                // Dropping to root
                destPath = fileName;
            } else {
                destPath = `${targetPath}/${fileName}`;
            }

            // Check if destination already exists
            const destNode = this.findNode(destPath);
            if (destNode) {
                const overwrite = await window.ModalManager.confirm(
                    `A ${destNode.isDirectory ? 'folder' : 'file'} named "${fileName}" already exists in the destination. Do you want to overwrite it?`,
                    'Name Conflict',
                    true
                );

                if (!overwrite) {
                    return;
                }

                // Delete existing item first
                await this.webdavClient.delete(destPath);

                // Clear undo history since we're overwriting
                this.lastMoveOperation = null;
            }

            // Perform the move
            await this.webdavClient.move(sourcePath, destPath);

            // Store undo information (only if not overwriting)
            if (!destNode) {
                this.lastMoveOperation = {
                    sourcePath: sourcePath,
                    destPath: destPath,
                    fileName: fileName,
                    isDirectory: isDirectory
                };
            }

            // If the moved item was the currently selected file, update the selection
            if (this.selectedPath === sourcePath) {
                this.selectedPath = destPath;

                // Update editor's current file path if it's the file being moved
                if (!this.draggedIsDir && window.editor && window.editor.currentFile === sourcePath) {
                    window.editor.currentFile = destPath;
                    if (window.editor.filenameInput) {
                        window.editor.filenameInput.value = destPath;
                    }
                }

                // Notify file select callback if it's a file
                if (!this.draggedIsDir && this.onFileSelect) {
                    this.onFileSelect({ path: destPath, isDirectory: false });
                }
            }

            // Reload the tree
            await this.load();

            // Re-select the moved item
            this.selectAndExpandPath(destPath);

            showNotification(`Moved ${fileName} successfully`, 'success');
        } catch (error) {
            console.error('Failed to move item:', error);
            showNotification('Failed to move item: ' + error.message, 'danger');
        }
    }

    async load() {
        try {
            // Check if a collection is selected
            if (!this.webdavClient.currentCollection) {
                // No collection selected - show empty state
                this.tree = [];
                this.renderEmptyState();
                return;
            }

            const items = await this.webdavClient.propfind('', 'infinity');
            this.tree = this.webdavClient.buildTree(items);
            this.render();
        } catch (error) {
            console.error('Failed to load file tree:', error);
            showNotification('Failed to load files', 'error');
        }
    }

    renderEmptyState() {
        this.container.innerHTML = `
            <div style="padding: 20px; text-align: center; color: #666;">
                <p style="margin-bottom: 10px;">📁 No collection selected</p>
                <p style="font-size: 0.9em;">Create a collection using the + button above</p>
            </div>
        `;
    }

    render() {
        this.container.innerHTML = '';
        this.renderNodes(this.tree, this.container, 0);
    }

    renderNodes(nodes, parentElement, level) {
        nodes.forEach(node => {
            // Filter out images and image directories in view mode
            if (this.filterImagesInViewMode) {
                // Skip image files
                if (!node.isDirectory && PathUtils.isBinaryFile(node.path)) {
                    return;
                }

                // Skip image directories
                if (node.isDirectory && PathUtils.isImageDirectory(node.path)) {
                    return;
                }
            }

            const nodeWrapper = document.createElement('div');
            nodeWrapper.className = 'tree-node-wrapper';

            // Create node element
            const nodeElement = this.createNodeElement(node, level);
            nodeWrapper.appendChild(nodeElement);

            // Create children container for directories
            if (node.isDirectory) {
                const childContainer = document.createElement('div');
                childContainer.className = 'tree-children';
                childContainer.style.display = 'none';
                childContainer.dataset.parent = node.path;
                childContainer.style.marginLeft = `${(level + 1) * 12}px`;

                // Only render children if they exist
                if (node.children && node.children.length > 0) {
                    this.renderNodes(node.children, childContainer, level + 1);
                } else {
                    // Empty directory - show empty state message
                    const emptyMessage = document.createElement('div');
                    emptyMessage.className = 'tree-empty-message';
                    emptyMessage.textContent = 'Empty folder';
                    childContainer.appendChild(emptyMessage);
                }

                nodeWrapper.appendChild(childContainer);

                // Make toggle functional for ALL directories (including empty ones)
                const toggle = nodeElement.querySelector('.tree-node-toggle');
                if (toggle) {
                    const toggleHandler = (e) => {
                        e.stopPropagation();
                        const isHidden = childContainer.style.display === 'none';
                        childContainer.style.display = isHidden ? 'block' : 'none';
                        toggle.style.transform = isHidden ? 'rotate(90deg)' : 'rotate(0deg)';
                        toggle.classList.toggle('expanded');
                    };

                    // Add click listener to toggle icon
                    toggle.addEventListener('click', toggleHandler);

                    // Also allow double-click on the node to toggle
                    nodeElement.addEventListener('dblclick', toggleHandler);

                    // Make toggle cursor pointer for all directories
                    toggle.style.cursor = 'pointer';
                }
            }

            parentElement.appendChild(nodeWrapper);
        });
    }


    // toggleFolder is no longer needed as the event listener is added in renderNodes.

    selectFile(path) {
        this.selectedPath = path;
        this.updateSelection();
        if (this.onFileSelect) {
            this.onFileSelect({ path, isDirectory: false });
        }
    }

    selectFolder(path) {
        this.selectedPath = path;
        this.updateSelection();
        if (this.onFolderSelect) {
            this.onFolderSelect({ path, isDirectory: true });
        }
    }

    /**
     * Find a node by path
     * @param {string} path - The path to find
     * @returns {Object|null} The node or null if not found
     */
    findNode(path) {
        const search = (nodes, targetPath) => {
            for (const node of nodes) {
                if (node.path === targetPath) {
                    return node;
                }
                if (node.children && node.children.length > 0) {
                    const found = search(node.children, targetPath);
                    if (found) return found;
                }
            }
            return null;
        };

        return search(this.tree, path);
    }

    /**
     * Get all files in a directory (direct children only)
     * @param {string} dirPath - The directory path
     * @returns {Array} Array of file nodes
     */
    getDirectoryFiles(dirPath) {
        const dirNode = this.findNode(dirPath);
        if (dirNode && dirNode.children) {
            return dirNode.children.filter(child => !child.isDirectory);
        }
        return [];
    }

    updateSelection() {
        // Remove previous selection
        this.container.querySelectorAll('.tree-node').forEach(node => {
            node.classList.remove('active');
        });

        // Add selection to current and all parent directories
        if (this.selectedPath) {
            // Add active class to the selected file/folder
            const node = this.container.querySelector(`[data-path="${this.selectedPath}"]`);
            if (node) {
                node.classList.add('active');
            }

            // Add active class to all parent directories
            const parts = this.selectedPath.split('/');
            let currentPath = '';
            for (let i = 0; i < parts.length - 1; i++) {
                currentPath = currentPath ? `${currentPath}/${parts[i]}` : parts[i];
                const parentNode = this.container.querySelector(`[data-path="${currentPath}"]`);
                if (parentNode) {
                    parentNode.classList.add('active');
                }
            }
        }
    }

    /**
     * Highlight a file as active and expand all parent directories
     * @param {string} path - The file path to highlight
     */
    selectAndExpandPath(path) {
        this.selectedPath = path;

        // Expand all parent directories
        this.expandParentDirectories(path);

        // Update selection
        this.updateSelection();
    }

    /**
     * Expand all parent directories of a given path
     * @param {string} path - The file path
     */
    expandParentDirectories(path) {
        // Get all parent paths
        const parts = path.split('/');
        let currentPath = '';

        for (let i = 0; i < parts.length - 1; i++) {
            currentPath = currentPath ? `${currentPath}/${parts[i]}` : parts[i];

            // Find the node with this path
            const parentNode = this.container.querySelector(`[data-path="${currentPath}"]`);
            if (parentNode && parentNode.dataset.isdir === 'true') {
                // Find the children container
                const wrapper = parentNode.closest('.tree-node-wrapper');
                if (wrapper) {
                    const childContainer = wrapper.querySelector('.tree-children');
                    if (childContainer && childContainer.style.display === 'none') {
                        // Expand it
                        childContainer.style.display = 'block';
                        const toggle = parentNode.querySelector('.tree-node-toggle');
                        if (toggle) {
                            toggle.classList.add('expanded');
                        }
                    }
                }
            }
        }
    }

    createNodeElement(node, level) {
        const nodeElement = document.createElement('div');
        nodeElement.className = 'tree-node';
        nodeElement.dataset.path = node.path;
        nodeElement.dataset.isdir = node.isDirectory;
        nodeElement.style.paddingLeft = `${level * 12}px`;

        // Enable drag and drop in edit mode with long-press detection
        if (this.isEditMode()) {
            // Start with draggable disabled
            nodeElement.draggable = false;
            this.setupNodeDragHandlers(nodeElement, node);
            this.setupLongPressDetection(nodeElement, node);
        }

        // Create toggle/icon container
        const iconContainer = document.createElement('span');
        iconContainer.className = 'tree-node-icon';

        if (node.isDirectory) {
            // Create toggle icon for folders
            const toggle = document.createElement('i');
            toggle.className = 'bi bi-chevron-right tree-node-toggle';
            toggle.style.fontSize = '12px';
            iconContainer.appendChild(toggle);
        } else {
            // Create file icon
            const fileIcon = document.createElement('i');
            fileIcon.className = 'bi bi-file-earmark-text';
            fileIcon.style.fontSize = '14px';
            iconContainer.appendChild(fileIcon);
        }

        const title = document.createElement('span');
        title.className = 'tree-node-title';
        title.textContent = node.name;

        nodeElement.appendChild(iconContainer);
        nodeElement.appendChild(title);

        return nodeElement;
    }

    setupLongPressDetection(nodeElement, node) {
        // Mouse down - start long-press timer
        nodeElement.addEventListener('mousedown', (e) => {
            // Ignore if clicking on toggle button
            if (e.target.closest('.tree-node-toggle')) {
                return;
            }

            this.mouseDownNode = nodeElement;

            // Start timer for long-press
            this.longPressTimer = setTimeout(() => {
                // Long-press threshold met - enable dragging
                this.isDraggingEnabled = true;
                nodeElement.draggable = true;
                nodeElement.classList.add('drag-ready');

                // Change cursor to grab
                nodeElement.style.cursor = 'grab';
            }, this.longPressThreshold);
        });

        // Mouse up - cancel long-press timer
        nodeElement.addEventListener('mouseup', () => {
            this.clearLongPressTimer();
        });

        // Mouse leave - cancel long-press timer
        nodeElement.addEventListener('mouseleave', () => {
            this.clearLongPressTimer();
        });

        // Mouse move - cancel long-press if moved too much
        let startX, startY;
        nodeElement.addEventListener('mousedown', (e) => {
            startX = e.clientX;
            startY = e.clientY;
        });

        nodeElement.addEventListener('mousemove', (e) => {
            if (this.longPressTimer && !this.isDraggingEnabled) {
                const deltaX = Math.abs(e.clientX - startX);
                const deltaY = Math.abs(e.clientY - startY);

                // If mouse moved more than threshold, cancel long-press
                if (deltaX > Config.MOUSE_MOVE_THRESHOLD || deltaY > Config.MOUSE_MOVE_THRESHOLD) {
                    this.clearLongPressTimer();
                }
            }
        });
    }

    clearLongPressTimer() {
        if (this.longPressTimer) {
            clearTimeout(this.longPressTimer);
            this.longPressTimer = null;
        }

        // Reset dragging state if not currently dragging
        if (!this.draggedPath && this.mouseDownNode) {
            this.mouseDownNode.draggable = false;
            this.mouseDownNode.classList.remove('drag-ready');
            this.mouseDownNode.style.cursor = '';
            this.isDraggingEnabled = false;
        }

        this.mouseDownNode = null;
    }

    formatSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 10) / 10 + ' ' + sizes[i];
    }

    newFile() {
        this.selectedPath = null;
        this.updateSelection();
        // Potentially clear editor via callback
        if (this.onFileSelect) {
            this.onFileSelect({ path: null, isDirectory: false });
        }
    }

    async createFile(parentPath, filename) {
        try {
            const fullPath = parentPath ? `${parentPath}/${filename}` : filename;
            await this.webdavClient.put(fullPath, '# New File\n\nStart typing...\n');
            await this.load();
            this.selectFile(fullPath); // Select the new file
            showNotification('File created', 'success');
            return fullPath;
        } catch (error) {
            console.error('Failed to create file:', error);
            showNotification('Failed to create file', 'error');
            throw error;
        }
    }

    async createFolder(parentPath, foldername) {
        try {
            const fullPath = parentPath ? `${parentPath}/${foldername}` : foldername;
            await this.webdavClient.mkcol(fullPath);
            await this.load();
            showNotification('Folder created', 'success');
            return fullPath;
        } catch (error) {
            console.error('Failed to create folder:', error);
            showNotification('Failed to create folder', 'error');
            throw error;
        }
    }

    async uploadFile(parentPath, file) {
        try {
            const fullPath = parentPath ? `${parentPath}/${file.name}` : file.name;
            const content = await file.arrayBuffer();
            await this.webdavClient.putBinary(fullPath, content);
            await this.load();
            showNotification(`Uploaded ${file.name}`, 'success');
            return fullPath;
        } catch (error) {
            console.error('Failed to upload file:', error);
            showNotification('Failed to upload file', 'error');
            throw error;
        }
    }

    async downloadFile(path) {
        try {
            const content = await this.webdavClient.get(path);
            const filename = PathUtils.getFileName(path);
            DownloadUtils.triggerDownload(content, filename);
            showNotification('Downloaded', 'success');
        } catch (error) {
            console.error('Failed to download file:', error);
            showNotification('Failed to download file', 'error');
        }
    }

    async downloadFolder(path) {
        try {
            showNotification('Creating zip...', 'info');
            // Get all files in folder
            const items = await this.webdavClient.propfind(path, 'infinity');
            const files = items.filter(item => !item.isDirectory);

            // Use JSZip to create zip file
            const JSZip = window.JSZip;
            if (!JSZip) {
                throw new Error('JSZip not loaded');
            }

            const zip = new JSZip();
            const folder = zip.folder(PathUtils.getFileName(path) || 'download');

            // Add all files to zip
            for (const file of files) {
                const content = await this.webdavClient.get(file.path);
                const relativePath = file.path.replace(path + '/', '');
                folder.file(relativePath, content);
            }

            // Generate zip
            const zipBlob = await zip.generateAsync({ type: 'blob' });
            const zipFilename = `${PathUtils.getFileName(path) || 'download'}.zip`;
            DownloadUtils.triggerDownload(zipBlob, zipFilename);
            showNotification('Downloaded', 'success');
        } catch (error) {
            console.error('Failed to download folder:', error);
            showNotification('Failed to download folder', 'error');
        }
    }

    // triggerDownload method moved to DownloadUtils in utils.js

    /**
     * Get the first markdown file in the tree
     * Returns the path of the first .md file found, or null if none exist
     */
    getFirstMarkdownFile() {
        const findFirstFile = (nodes) => {
            for (const node of nodes) {
                // If it's a file and ends with .md, return it
                if (!node.isDirectory && node.path.endsWith('.md')) {
                    return node.path;
                }
                // If it's a directory with children, search recursively
                if (node.isDirectory && node.children && node.children.length > 0) {
                    const found = findFirstFile(node.children);
                    if (found) return found;
                }
            }
            return null;
        };

        return findFirstFile(this.tree);
    }
}

