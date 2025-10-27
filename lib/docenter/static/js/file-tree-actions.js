/**
 * File Tree Actions Manager
 * Centralized handling of all tree operations
 */

class FileTreeActions {
    constructor(webdavClient, fileTree, editor) {
        this.webdavClient = webdavClient;
        this.fileTree = fileTree;
        this.editor = editor;
        this.clipboard = null;
    }

    /**
     * Validate and sanitize filename/folder name
     * Returns { valid: boolean, sanitized: string, message: string }
     * Now uses ValidationUtils from utils.js
     */
    validateFileName(name, isFolder = false) {
        return ValidationUtils.validateFileName(name, isFolder);
    }

    async execute(action, targetPath, isDirectory) {
        const handler = this.actions[action];
        if (!handler) {
            console.error(`Unknown action: ${action}`);
            return;
        }

        try {
            await handler.call(this, targetPath, isDirectory);
        } catch (error) {
            console.error(`Action failed: ${action}`, error);
            showNotification(`Failed to ${action}`, 'error');
        }
    }

    actions = {
        open: async function (path, isDir) {
            if (!isDir) {
                await this.editor.loadFile(path);
            }
        },

        'new-file': async function (path, isDir) {
            if (!isDir) return;

            const filename = await window.ModalManager.prompt(
                'Enter filename (lowercase, underscore only):',
                'new_file.md',
                'New File'
            );

            if (!filename) return;

            let finalFilename = filename;
            const validation = this.validateFileName(filename, false);

            if (!validation.valid) {
                showNotification(validation.message, 'warning');

                // Ask if user wants to use sanitized version
                if (validation.sanitized) {
                    const useSanitized = await window.ModalManager.confirm(
                        `${filename} → ${validation.sanitized}`,
                        'Use sanitized name?',
                        false
                    );
                    if (useSanitized) {
                        finalFilename = validation.sanitized;
                    } else {
                        return;
                    }
                } else {
                    return;
                }
            }

            const fullPath = `${path}/${finalFilename}`.replace(/\/+/g, '/');
            await this.webdavClient.put(fullPath, '# New File\n\n');

            // Clear undo history since new file was created
            if (this.fileTree.lastMoveOperation) {
                this.fileTree.lastMoveOperation = null;
            }

            await this.fileTree.load();
            showNotification(`Created ${finalFilename}`, 'success');
            await this.editor.loadFile(fullPath);
        },

        'new-folder': async function (path, isDir) {
            if (!isDir) return;

            const foldername = await window.ModalManager.prompt(
                'Enter folder name (lowercase, underscore only):',
                'new_folder',
                'New Folder'
            );

            if (!foldername) return;

            let finalFoldername = foldername;
            const validation = this.validateFileName(foldername, true);

            if (!validation.valid) {
                showNotification(validation.message, 'warning');

                if (validation.sanitized) {
                    const useSanitized = await window.ModalManager.confirm(
                        `${foldername} → ${validation.sanitized}`,
                        'Use sanitized name?',
                        false
                    );
                    if (useSanitized) {
                        finalFoldername = validation.sanitized;
                    } else {
                        return;
                    }
                } else {
                    return;
                }
            }

            const fullPath = `${path}/${finalFoldername}`.replace(/\/+/g, '/');
            await this.webdavClient.mkcol(fullPath);

            // Clear undo history since new folder was created
            if (this.fileTree.lastMoveOperation) {
                this.fileTree.lastMoveOperation = null;
            }

            await this.fileTree.load();
            showNotification(`Created folder ${finalFoldername}`, 'success');
        },

        rename: async function (path, isDir) {
            const oldName = path.split('/').pop();
            const newName = await window.ModalManager.prompt(
                'Rename to:',
                oldName,
                'Rename'
            );

            if (newName && newName !== oldName) {
                const parentPath = path.substring(0, path.lastIndexOf('/'));
                const newPath = parentPath ? `${parentPath}/${newName}` : newName;
                await this.webdavClient.move(path, newPath);

                // Clear undo history since manual rename occurred
                if (this.fileTree.lastMoveOperation) {
                    this.fileTree.lastMoveOperation = null;
                }

                await this.fileTree.load();
                showNotification('Renamed', 'success');
            }
        },

        copy: async function (path, isDir) {
            this.clipboard = { path, operation: 'copy', isDirectory: isDir };
            // No notification for copy - it's a quick operation
            this.updatePasteMenuItem();
        },

        cut: async function (path, isDir) {
            this.clipboard = { path, operation: 'cut', isDirectory: isDir };
            // No notification for cut - it's a quick operation
            this.updatePasteMenuItem();
        },

        paste: async function (targetPath, isDir) {
            if (!this.clipboard || !isDir) return;

            const itemName = this.clipboard.path.split('/').pop();
            const destPath = `${targetPath}/${itemName}`.replace(/\/+/g, '/');

            if (this.clipboard.operation === 'copy') {
                await this.webdavClient.copy(this.clipboard.path, destPath);
                // No notification for paste - file tree updates show the result
            } else {
                await this.webdavClient.move(this.clipboard.path, destPath);
                this.clipboard = null;
                this.updatePasteMenuItem();
                // No notification for move - file tree updates show the result
            }

            await this.fileTree.load();
        },

        delete: async function (path, isDir) {
            const name = path.split('/').pop() || this.webdavClient.currentCollection;
            const type = isDir ? 'folder' : 'file';

            // Check if this is a root-level collection (empty path or single-level path)
            const pathParts = path.split('/').filter(p => p.length > 0);
            const isCollection = pathParts.length === 0;

            if (isCollection) {
                // Deleting a collection - use backend API
                const confirmed = await window.ModalManager.confirm(
                    `Are you sure you want to delete the collection "${name}"? This will delete all files and folders in it.`,
                    'Delete Collection?',
                    true
                );

                if (!confirmed) return;

                try {
                    // Call backend API to delete collection
                    const response = await fetch(`/api/collections/${name}`, {
                        method: 'DELETE'
                    });

                    if (!response.ok) {
                        const error = await response.text();
                        throw new Error(error || 'Failed to delete collection');
                    }

                    showNotification(`Collection "${name}" deleted successfully`, 'success');

                    // Reload the page to refresh collections list
                    window.location.href = '/';
                } catch (error) {
                    Logger.error('Failed to delete collection:', error);
                    showNotification(`Failed to delete collection: ${error.message}`, 'error');
                }
            } else {
                // Deleting a regular file/folder - use WebDAV
                const confirmed = await window.ModalManager.confirm(
                    `Are you sure you want to delete ${name}?`,
                    `Delete this ${type}?`,
                    true
                );

                if (!confirmed) return;

                await this.webdavClient.delete(path);

                // Clear undo history since manual delete occurred
                if (this.fileTree.lastMoveOperation) {
                    this.fileTree.lastMoveOperation = null;
                }

                await this.fileTree.load();
                showNotification(`Deleted ${name}`, 'success');
            }
        },

        download: async function (path, isDir) {
            Logger.info(`Downloading ${isDir ? 'folder' : 'file'}: ${path}`);

            if (isDir) {
                await this.fileTree.downloadFolder(path);
            } else {
                await this.fileTree.downloadFile(path);
            }
        },

        upload: async function (path, isDir) {
            if (!isDir) return;

            const input = document.createElement('input');
            input.type = 'file';
            input.multiple = true;

            input.onchange = async (e) => {
                const files = Array.from(e.target.files);
                for (const file of files) {
                    const fullPath = `${path}/${file.name}`.replace(/\/+/g, '/');
                    const content = await file.arrayBuffer();
                    await this.webdavClient.putBinary(fullPath, content);
                    showNotification(`Uploaded ${file.name}`, 'success');
                }
                await this.fileTree.load();
            };

            input.click();
        },

        'copy-to-collection': async function (path, isDir) {
            // Get list of available collections
            const collections = await this.webdavClient.getCollections();
            const currentCollection = this.webdavClient.currentCollection;

            // Filter out current collection
            const otherCollections = collections.filter(c => c !== currentCollection);

            if (otherCollections.length === 0) {
                showNotification('No other collections available', 'warning');
                return;
            }

            // Show collection selection dialog
            const targetCollection = await this.showCollectionSelectionDialog(
                otherCollections,
                `Copy ${PathUtils.getFileName(path)} to collection:`
            );

            if (!targetCollection) return;

            // Copy the file/folder
            await this.copyToCollection(path, isDir, currentCollection, targetCollection);
        },

        'move-to-collection': async function (path, isDir) {
            // Get list of available collections
            const collections = await this.webdavClient.getCollections();
            const currentCollection = this.webdavClient.currentCollection;

            // Filter out current collection
            const otherCollections = collections.filter(c => c !== currentCollection);

            if (otherCollections.length === 0) {
                showNotification('No other collections available', 'warning');
                return;
            }

            // Show collection selection dialog
            const targetCollection = await this.showCollectionSelectionDialog(
                otherCollections,
                `Move ${PathUtils.getFileName(path)} to collection:`
            );

            if (!targetCollection) return;

            // Move the file/folder
            await this.moveToCollection(path, isDir, currentCollection, targetCollection);
        }
    };

    // Old deprecated modal methods removed - all modals now use window.ModalManager

    updatePasteMenuItem() {
        const pasteItem = document.getElementById('pasteMenuItem');
        if (pasteItem) {
            pasteItem.style.display = this.clipboard ? 'flex' : 'none';
        }
    }

    /**
     * Show a dialog to select a collection
     * @param {Array<string>} collections - List of collection names
     * @param {string} message - Dialog message
     * @returns {Promise<string|null>} Selected collection or null if cancelled
     */
    async showCollectionSelectionDialog(collections, message) {
        // Prevent duplicate modals
        if (this._collectionModalShowing) {
            Logger.warn('Collection selection modal is already showing');
            return null;
        }
        this._collectionModalShowing = true;

        // Create a custom modal with radio buttons for collection selection
        const modal = document.createElement('div');
        modal.className = 'modal fade';
        modal.innerHTML = `
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title"><i class="bi bi-folder-symlink"></i> Select Collection</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <p class="mb-3">${message}</p>
                        <div class="collection-list" style="max-height: 300px; overflow-y: auto;">
                            ${collections.map((c, i) => `
                                <div class="form-check p-2 mb-2 rounded border collection-option" style="cursor: pointer; transition: all 0.2s;">
                                    <input class="form-check-input" type="radio" name="collection" id="collection-${i}" value="${c}" ${i === 0 ? 'checked' : ''}>
                                    <label class="form-check-label w-100" for="collection-${i}" style="cursor: pointer;">
                                        <i class="bi bi-folder"></i> <strong>${c}</strong>
                                    </label>
                                </div>
                            `).join('')}
                        </div>
                        <div id="confirmationPreview" class="alert alert-info mt-3" style="display: none;">
                            <i class="bi bi-info-circle"></i> <span id="confirmationText"></span>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn-flat btn-flat-secondary" data-bs-dismiss="modal">
                            <i class="bi bi-x-circle"></i> Cancel
                        </button>
                        <button type="button" class="btn-flat btn-flat-primary" id="confirmCollectionBtn">
                            <i class="bi bi-check-circle"></i> OK
                        </button>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
        const bsModal = new bootstrap.Modal(modal);

        // Extract file name and action from message
        // Message format: "Copy filename to collection:" or "Move filename to collection:"
        const messageMatch = message.match(/(Copy|Move)\s+(.+?)\s+to collection:/);
        const action = messageMatch ? messageMatch[1].toLowerCase() : 'copy';
        const fileName = messageMatch ? messageMatch[2] : 'item';

        // Get confirmation preview elements
        const confirmationPreview = modal.querySelector('#confirmationPreview');
        const confirmationText = modal.querySelector('#confirmationText');

        // Function to update confirmation message
        const updateConfirmation = (collectionName) => {
            confirmationText.textContent = `"${fileName}" will be ${action}d to "${collectionName}"`;
            confirmationPreview.style.display = 'block';
        };

        // Add hover effects and click handlers for collection options
        const collectionOptions = modal.querySelectorAll('.collection-option');
        collectionOptions.forEach(option => {
            // Hover effect
            option.addEventListener('mouseenter', () => {
                option.style.backgroundColor = 'var(--bs-light)';
                option.style.borderColor = 'var(--bs-primary)';
            });
            option.addEventListener('mouseleave', () => {
                const radio = option.querySelector('input[type="radio"]');
                if (!radio.checked) {
                    option.style.backgroundColor = '';
                    option.style.borderColor = '';
                }
            });

            // Click on the whole div to select
            option.addEventListener('click', () => {
                const radio = option.querySelector('input[type="radio"]');
                radio.checked = true;

                // Update confirmation message
                updateConfirmation(radio.value);

                // Update all options styling
                collectionOptions.forEach(opt => {
                    const r = opt.querySelector('input[type="radio"]');
                    if (r.checked) {
                        opt.style.backgroundColor = 'var(--bs-primary-bg-subtle)';
                        opt.style.borderColor = 'var(--bs-primary)';
                    } else {
                        opt.style.backgroundColor = '';
                        opt.style.borderColor = '';
                    }
                });
            });

            // Set initial styling for checked option
            const radio = option.querySelector('input[type="radio"]');
            if (radio.checked) {
                option.style.backgroundColor = 'var(--bs-primary-bg-subtle)';
                option.style.borderColor = 'var(--bs-primary)';
                // Show initial confirmation
                updateConfirmation(radio.value);
            }
        });

        return new Promise((resolve) => {
            const confirmBtn = modal.querySelector('#confirmCollectionBtn');

            confirmBtn.addEventListener('click', () => {
                const selected = modal.querySelector('input[name="collection"]:checked');
                this._collectionModalShowing = false;
                bsModal.hide();
                resolve(selected ? selected.value : null);
            });

            modal.addEventListener('hidden.bs.modal', () => {
                modal.remove();
                this._collectionModalShowing = false;
                resolve(null);
            });

            bsModal.show();
        });
    }

    /**
     * Copy a file or folder to another collection
     */
    async copyToCollection(path, isDir, sourceCollection, targetCollection) {
        try {
            Logger.info(`Copying ${path} from ${sourceCollection} to ${targetCollection}`);

            if (isDir) {
                // Copy folder recursively
                await this.copyFolderToCollection(path, sourceCollection, targetCollection);
            } else {
                // Copy single file
                await this.copyFileToCollection(path, sourceCollection, targetCollection);
            }

            showNotification(`Copied to ${targetCollection}`, 'success');
        } catch (error) {
            Logger.error('Failed to copy to collection:', error);
            showNotification('Failed to copy to collection', 'error');
            throw error;
        }
    }

    /**
     * Move a file or folder to another collection
     */
    async moveToCollection(path, isDir, sourceCollection, targetCollection) {
        try {
            Logger.info(`Moving ${path} from ${sourceCollection} to ${targetCollection}`);

            // First copy
            await this.copyToCollection(path, isDir, sourceCollection, targetCollection);

            // Then delete from source
            await this.webdavClient.delete(path);
            await this.fileTree.load();

            showNotification(`Moved to ${targetCollection}`, 'success');
        } catch (error) {
            Logger.error('Failed to move to collection:', error);
            showNotification('Failed to move to collection', 'error');
            throw error;
        }
    }

    /**
     * Copy a single file to another collection
     */
    async copyFileToCollection(path, sourceCollection, targetCollection) {
        // Read file from source collection
        const content = await this.webdavClient.get(path);

        // Write to target collection
        const originalCollection = this.webdavClient.currentCollection;
        this.webdavClient.setCollection(targetCollection);

        // Ensure parent directories exist in target collection
        await this.webdavClient.ensureParentDirectories(path);

        await this.webdavClient.put(path, content);
        this.webdavClient.setCollection(originalCollection);
    }

    /**
     * Copy a folder recursively to another collection
     * @param {string} folderPath - Path of the folder to copy
     * @param {string} sourceCollection - Source collection name
     * @param {string} targetCollection - Target collection name
     * @param {Set} visitedPaths - Set of already visited paths to prevent infinite loops
     */
    async copyFolderToCollection(folderPath, sourceCollection, targetCollection, visitedPaths = new Set()) {
        // Prevent infinite loops by tracking visited paths
        if (visitedPaths.has(folderPath)) {
            Logger.warn(`Skipping already visited path: ${folderPath}`);
            return;
        }
        visitedPaths.add(folderPath);

        Logger.info(`Copying folder: ${folderPath} from ${sourceCollection} to ${targetCollection}`);

        // Set to source collection to list items
        const originalCollection = this.webdavClient.currentCollection;
        this.webdavClient.setCollection(sourceCollection);

        // Get only direct children (not recursive to avoid infinite loop)
        const items = await this.webdavClient.list(folderPath, false);
        Logger.debug(`Found ${items.length} items in ${folderPath}:`, items.map(i => i.path));

        // Create the folder in target collection
        this.webdavClient.setCollection(targetCollection);

        try {
            // Ensure parent directories exist first
            await this.webdavClient.ensureParentDirectories(folderPath + '/dummy.txt');
            // Then create the folder itself
            await this.webdavClient.createFolder(folderPath);
            Logger.debug(`Created folder: ${folderPath}`);
        } catch (error) {
            // Folder might already exist (405 Method Not Allowed), ignore error
            if (error.message && error.message.includes('405')) {
                Logger.debug(`Folder ${folderPath} already exists (405)`);
            } else {
                Logger.debug('Folder might already exist:', error);
            }
        }

        // Copy all items
        for (const item of items) {
            if (item.isDirectory) {
                // Recursively copy subdirectory
                await this.copyFolderToCollection(item.path, sourceCollection, targetCollection, visitedPaths);
            } else {
                // Copy file
                this.webdavClient.setCollection(sourceCollection);
                const content = await this.webdavClient.get(item.path);
                this.webdavClient.setCollection(targetCollection);
                // Ensure parent directories exist before copying file
                await this.webdavClient.ensureParentDirectories(item.path);
                await this.webdavClient.put(item.path, content);
                Logger.debug(`Copied file: ${item.path}`);
            }
        }

        this.webdavClient.setCollection(originalCollection);
    }
}