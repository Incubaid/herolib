// Global state
let currentWs = localStorage.getItem('heroprompt-current-ws') || 'default';
let selected = new Set();
let expandedDirs = new Set();
let searchQuery = '';

// Utility functions
const el = (id) => document.getElementById(id);
const qs = (selector) => document.querySelector(selector);
const qsa = (selector) => document.querySelectorAll(selector);

// File extension detection utility
const getFileExtension = (filename) => {
    const parts = filename.split('.');
    return parts.length > 1 ? parts.pop().toLowerCase() : '';
};

// File size formatting utility
const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
};

// Date formatting utility
const formatDate = (date) => {
    const now = new Date();
    const diffTime = Math.abs(now - date);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;
    if (diffDays < 30) return `${Math.ceil(diffDays / 7)} weeks ago`;
    return date.toLocaleDateString();
};

// File icon mapping utility
const getFileIcon = (extension) => {
    const iconMap = {
        'js': '📜', 'ts': '📜', 'html': '🌐', 'css': '🎨', 'json': '📋',
        'md': '📝', 'txt': '📄', 'v': '⚡', 'go': '🐹', 'py': '🐍',
        'java': '☕', 'cpp': '⚙️', 'c': '⚙️', 'rs': '🦀', 'php': '🐘',
        'rb': '💎', 'sh': '🐚', 'yml': '📄', 'yaml': '📄', 'xml': '📄',
        'svg': '🖼️', 'png': '🖼️', 'jpg': '🖼️', 'jpeg': '🖼️', 'gif': '🖼️',
        'pdf': '📕', 'zip': '📦', 'tar': '📦', 'gz': '📦'
    };
    return iconMap[extension] || '📄';
};

// API helpers
async function api(url) {
    try {
        const r = await fetch(url);
        if (!r.ok) {
            console.warn(`API call failed: ${url} - ${r.status}`);
            return { error: `HTTP ${r.status}` };
        }
        return await r.json();
    } catch (e) {
        console.warn(`API call error: ${url}`, e);
        return { error: 'request failed' };
    }
}

async function post(url, data) {
    const form = new FormData();
    Object.entries(data).forEach(([k, v]) => form.append(k, v));
    try {
        const r = await fetch(url, { method: 'POST', body: form });
        if (!r.ok) {
            console.warn(`POST failed: ${url} - ${r.status}`);
            return { error: `HTTP ${r.status}` };
        }
        return await r.json();
    } catch (e) {
        console.warn(`POST error: ${url}`, e);
        return { error: 'request failed' };
    }
}

// Modal helpers
function showModal(id) {
    const modalEl = el(id);
    if (modalEl) {
        const modal = new bootstrap.Modal(modalEl);
        modal.show();
    }
}

function hideModal(id) {
    const modalEl = el(id);
    if (modalEl) {
        const modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) modal.hide();
    }
}

// Tab management
function switchTab(tabName) {
    // Update tab buttons
    qsa('.tab').forEach(tab => {
        tab.classList.remove('active');
        if (tab.getAttribute('data-tab') === tabName) {
            tab.classList.add('active');
        }
    });

    // Update tab panes
    qsa('.tab-pane').forEach(pane => {
        pane.style.display = 'none';
        if (pane.id === `tab-${tabName}`) {
            pane.style.display = 'block';
        }
    });
}

// Enhanced file tree implementation with better spacing and reliability
class SimpleFileTree {
    constructor(container) {
        this.container = container;
        this.loadedPaths = new Set();
        this.expandedDirs = new Set(); // Track expanded state locally
    }

    createFileItem(item, path, depth = 0) {
        const div = document.createElement('div');
        div.className = 'tree-item';
        div.dataset.path = path;
        div.dataset.type = item.type;
        div.dataset.depth = depth;

        const content = document.createElement('div');
        content.className = 'tree-item-content';
        // Use consistent 20px indentation per level
        content.style.paddingLeft = `${depth * 20 + 8}px`;

        // Checkbox
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'tree-checkbox';
        checkbox.checked = selected.has(path);
        checkbox.addEventListener('change', async (e) => {
            e.stopPropagation();
            if (checkbox.checked) {
                selected.add(path);
                // If this is a directory, also select all its children
                if (item.type === 'directory') {
                    await this.selectDirectoryChildren(path, true);
                } else {
                    // For files, update UI immediately since no async operation
                    this.updateSelectionUI();
                }
            } else {
                selected.delete(path);
                // If this is a directory, also deselect all its children
                if (item.type === 'directory') {
                    await this.selectDirectoryChildren(path, false);
                } else {
                    // For files, update UI immediately since no async operation
                    this.updateSelectionUI();
                }
            }
        });

        // Expand/collapse button for directories
        let expandBtn = null;
        if (item.type === 'directory') {
            expandBtn = document.createElement('button');
            expandBtn.className = 'tree-expand-btn';
            expandBtn.innerHTML = this.expandedDirs.has(path) ? '▼' : '▶';
            expandBtn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.toggleDirectory(path);
            });
        } else {
            // Spacer for files to align with directories
            expandBtn = document.createElement('span');
            expandBtn.className = 'tree-expand-spacer';
        }

        // Icon
        const icon = document.createElement('span');
        icon.className = 'tree-icon';
        icon.textContent = item.type === 'directory' ?
            (this.expandedDirs.has(path) ? '📂' : '�') : '📄';

        // Label
        const label = document.createElement('span');
        label.className = 'tree-label';
        label.textContent = item.name;
        label.addEventListener('click', (e) => {
            e.stopPropagation();
            if (item.type === 'file') {
                // Toggle file selection when clicking on file name
                checkbox.checked = !checkbox.checked;
                if (checkbox.checked) {
                    selected.add(path);
                } else {
                    selected.delete(path);
                }
                this.updateSelectionUI();
            } else {
                // Toggle directory expansion when clicking on directory name
                this.toggleDirectory(path);
            }
        });

        content.appendChild(checkbox);
        content.appendChild(expandBtn);
        content.appendChild(icon);
        content.appendChild(label);
        div.appendChild(content);

        return div;
    }

    async toggleDirectory(dirPath) {
        const isExpanded = this.expandedDirs.has(dirPath);
        const dirElement = qs(`[data-path="${dirPath}"]`);
        const expandBtn = dirElement?.querySelector('.tree-expand-btn');
        const icon = dirElement?.querySelector('.tree-icon');

        if (isExpanded) {
            // Collapse
            this.expandedDirs.delete(dirPath);
            if (expandBtn) expandBtn.innerHTML = '▶';
            if (icon) icon.textContent = '📁';
            this.removeChildren(dirPath);
            // Remove from loaded paths so it can be reloaded when expanded again
            this.loadedPaths.delete(dirPath);
        } else {
            // Expand - update UI optimistically but revert on error
            this.expandedDirs.add(dirPath);
            if (expandBtn) expandBtn.innerHTML = '▼';
            if (icon) icon.textContent = '📂';

            // Try to load children
            const success = await this.loadChildren(dirPath);

            // If loading failed, revert the UI state
            if (!success) {
                this.expandedDirs.delete(dirPath);
                if (expandBtn) expandBtn.innerHTML = '▶';
                if (icon) icon.textContent = '📁';
            }
        }
    }

    removeChildren(parentPath) {
        const items = qsa('.tree-item');
        const toRemove = [];

        items.forEach(item => {
            const itemPath = item.dataset.path;
            if (itemPath !== parentPath && itemPath.startsWith(parentPath + '/')) {
                toRemove.push(item);
                // Also remove from expanded dirs if it was expanded
                this.expandedDirs.delete(itemPath);
                this.loadedPaths.delete(itemPath);
            }
        });

        // Remove elements with animation
        toRemove.forEach(item => {
            item.style.transition = 'opacity 0.2s ease, max-height 0.2s ease';
            item.style.opacity = '0';
            item.style.maxHeight = '0';
            setTimeout(() => item.remove(), 200);
        });
    }

    async loadChildren(parentPath) {
        // Always reload children to ensure fresh data
        console.log('Loading children for:', parentPath);
        const r = await api(`/api/heroprompt/directory?name=${currentWs}&base=${encodeURIComponent(parentPath)}&path=`);

        if (r.error) {
            console.warn('Failed to load directory:', parentPath, r.error);
            return false; // Return false to indicate failure
        }

        // Sort items: directories first, then files
        const items = (r.items || []).sort((a, b) => {
            if (a.type !== b.type) {
                return a.type === 'directory' ? -1 : 1;
            }
            return a.name.localeCompare(b.name);
        });

        // Find the parent element
        const parentElement = qs(`[data-path="${parentPath}"]`);
        if (!parentElement) {
            console.warn('Parent element not found for path:', parentPath);
            return false; // Return false to indicate failure
        }

        const parentDepth = parseInt(parentElement.dataset.depth || '0');

        // Create document fragment for efficient DOM manipulation
        const fragment = document.createDocumentFragment();
        const childElements = [];

        // Create all child elements first
        for (const item of items) {
            const childPath = parentPath.endsWith('/') ?
                parentPath + item.name :
                parentPath + '/' + item.name;

            const childElement = this.createFileItem(item, childPath, parentDepth + 1);

            // Prepare for animation
            childElement.style.opacity = '0';
            childElement.style.maxHeight = '0';
            childElement.style.transition = 'opacity 0.2s ease, max-height 0.2s ease';

            fragment.appendChild(childElement);
            childElements.push(childElement);
        }

        // Insert all elements at once
        parentElement.insertAdjacentElement('afterend', fragment.firstChild);
        if (fragment.children.length > 1) {
            let insertAfter = parentElement.nextElementSibling;
            while (fragment.firstChild) {
                insertAfter.insertAdjacentElement('afterend', fragment.firstChild);
                insertAfter = insertAfter.nextElementSibling;
            }
        }

        // Trigger animations with staggered delay
        childElements.forEach((element, index) => {
            setTimeout(() => {
                element.style.opacity = '1';
                element.style.maxHeight = '30px';
            }, index * 20 + 10);
        });

        this.loadedPaths.add(parentPath);
        return true; // Return true to indicate success
    }

    getDepth(path) {
        // Calculate depth based on forward slashes, but handle root paths better
        if (!path || path === '/') return 0;
        const cleanPath = path.replace(/^\/+|\/+$/g, ''); // Remove leading/trailing slashes
        return cleanPath ? cleanPath.split('/').length - 1 : 0;
    }

    async previewFile(filePath) {
        const previewEl = el('preview');
        if (!previewEl) return;

        previewEl.innerHTML = '<div class="loading">Loading...</div>';

        const r = await api(`/api/heroprompt/file?name=${currentWs}&path=${encodeURIComponent(filePath)}`);

        if (r.error) {
            previewEl.innerHTML = `<div class="error-message">Error: ${r.error}</div>`;
            return;
        }

        previewEl.textContent = r.content || 'No content';
    }

    updateSelectionUI() {
        const selCountEl = el('selCount');
        const selCountTabEl = el('selCountTab');
        const tokenCountEl = el('tokenCount');
        const selectedCardsEl = el('selectedCards');

        const count = selected.size;

        if (selCountEl) selCountEl.textContent = count.toString();
        if (selCountTabEl) selCountTabEl.textContent = count.toString();

        // Update selection cards
        if (selectedCardsEl) {
            selectedCardsEl.innerHTML = '';

            if (count === 0) {
                selectedCardsEl.innerHTML = `
                    <div class="empty-selection-cards">
                        <i class="icon-empty"></i>
                        <p>No files selected</p>
                        <small>Use checkboxes in the explorer to select files and directories</small>
                    </div>
                `;
            } else {
                Array.from(selected).forEach(path => {
                    const card = this.createFileCard(path);
                    selectedCardsEl.appendChild(card);
                });
            }
        }

        // Estimate token count (rough approximation)
        const totalChars = Array.from(selected).join('\n').length;
        const tokens = Math.ceil(totalChars / 4);
        if (tokenCountEl) tokenCountEl.textContent = tokens.toString();
    }

    // Select or deselect all children of a directory recursively
    async selectDirectoryChildren(dirPath, select) {
        // First, get all children from API to update the selection state
        await this.selectDirectoryChildrenFromAPI(dirPath, select);

        // Then, update any currently visible children in the DOM
        this.updateVisibleCheckboxes();

        // Update the selection UI once at the end
        this.updateSelectionUI();
    }

    // Update all visible checkboxes to match the current selection state
    updateVisibleCheckboxes() {
        const treeItems = document.querySelectorAll('.tree-item');

        treeItems.forEach(item => {
            const itemPath = item.dataset.path;
            const checkbox = item.querySelector('.tree-checkbox');
            if (checkbox && itemPath) {
                // Set checkbox state based on current selection
                checkbox.checked = selected.has(itemPath);
            }
        });
    }

    // Select directory children using API to get complete recursive list
    async selectDirectoryChildrenFromAPI(dirPath, select) {
        try {
            const response = await fetch(`/api/heroprompt/workspaces/${encodeURIComponent(currentWs)}/list?path=${encodeURIComponent(dirPath)}`);
            if (response.ok) {
                const data = await response.json();
                if (data.children) {
                    data.children.forEach(child => {
                        const childPath = child.path;
                        if (select) {
                            selected.add(childPath);
                        } else {
                            selected.delete(childPath);
                        }
                    });
                }
            } else {
                console.error('Failed to fetch directory children:', response.status, response.statusText);
                const errorText = await response.text();
                console.error('Error response:', errorText);
            }
        } catch (error) {
            console.error('Error selecting directory children:', error);
        }
    }

    createFileCard(path) {
        const card = document.createElement('div');
        card.className = 'file-card';

        // Get file info
        const fileName = path.split('/').pop();
        const extension = getFileExtension(fileName);
        const isDirectory = this.isDirectory(path);

        card.dataset.type = isDirectory ? 'directory' : 'file';
        if (extension) {
            card.dataset.extension = extension;
        }

        // Get file stats (mock data for now - could be enhanced with real file stats)
        const stats = this.getFileStats(path);

        // Show full path for directories to help differentiate between same-named directories
        const displayPath = isDirectory ? path : path;

        card.innerHTML = `
            <div class="file-card-header">
                <div class="file-card-icon">
                    ${isDirectory ? '📁' : getFileIcon(extension)}
                </div>
                <div class="file-card-info">
                    <h4 class="file-card-name">${fileName}</h4>
                    <p class="file-card-path">${displayPath}</p>
                </div>
            </div>
            <div class="file-card-metadata">
                <div class="metadata-item">
                    <span class="icon">📄</span>
                    <span>${isDirectory ? 'Directory' : 'File'}</span>
                </div>
                ${extension ? `
                <div class="metadata-item">
                    <span class="icon">🏷️</span>
                    <span>${extension.toUpperCase()}</span>
                </div>
                ` : ''}
                <div class="metadata-item">
                    <span class="icon">📏</span>
                    <span>${stats.size}</span>
                </div>
                <div class="metadata-item">
                    <span class="icon">📅</span>
                    <span>${stats.modified}</span>
                </div>
            </div>
            <div class="file-card-actions">
                ${!isDirectory ? `
                <button class="card-btn card-btn-primary" onclick="fileTree.previewFileInModal('${path}')">
                    <i class="icon-file"></i>
                    Preview
                </button>
                ` : ''}
                <button class="card-btn card-btn-danger" onclick="fileTree.removeFromSelection('${path}')">
                    <i class="icon-close"></i>
                    Remove
                </button>
            </div>
        `;

        return card;
    }


    isDirectory(path) {
        // Check if path corresponds to a directory in the tree
        const treeItem = qs(`[data-path="${path}"]`);
        return treeItem && treeItem.dataset.type === 'directory';
    }

    getFileStats(path) {
        // Mock file stats - in a real implementation, this would come from the API
        return {
            size: formatFileSize(Math.floor(Math.random() * 100000) + 1000),
            modified: formatDate(new Date(Date.now() - Math.floor(Math.random() * 30) * 24 * 60 * 60 * 1000))
        };
    }

    async previewFileInModal(filePath) {
        // Create and show modal for file preview
        const modal = document.createElement('div');
        modal.className = 'modal fade file-preview-modal';
        modal.id = 'filePreviewModal';
        modal.innerHTML = `
            <div class="modal-dialog modal-xl">
                <div class="modal-content modal-content-dark">
                    <div class="modal-header modal-header-dark">
                        <div class="modal-title-container">
                            <h5 class="modal-title">${getFileIcon(getFileExtension(filePath.split('/').pop()))} ${filePath.split('/').pop()}</h5>
                            <span class="modal-subtitle">${filePath}</span>
                        </div>
                        <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body modal-body-dark">
                        <div id="modalPreviewContent" class="code-preview-container">
                            <div class="loading">Loading file content...</div>
                        </div>
                    </div>
                    <div class="modal-footer modal-footer-dark">
                        <div class="file-info">
                            <span id="fileStats" class="file-stats"></span>
                        </div>
                        <div class="modal-actions">
                            <button type="button" class="btn btn-secondary btn-dark" data-bs-dismiss="modal">
                                <i class="icon-close"></i> Close
                            </button>
                            <button type="button" class="btn btn-primary" onclick="fileTree.copyModalContent()">
                                <i class="icon-copy"></i> Copy Content
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);
        const bootstrapModal = new bootstrap.Modal(modal);
        bootstrapModal.show();

        // Load file content
        const r = await api(`/api/heroprompt/file?name=${currentWs}&path=${encodeURIComponent(filePath)}`);
        const contentEl = el('modalPreviewContent');

        if (r.error) {
            contentEl.innerHTML = `<div class="error-message">Error: ${r.error}</div>`;
        } else {
            const content = r.content || 'No content';
            this.renderCodePreview(contentEl, content, filePath);

            // Update file stats
            const statsEl = el('fileStats');
            if (statsEl) {
                const lines = content.split('\n').length;
                const chars = content.length;
                const words = content.split(/\s+/).filter(w => w.length > 0).length;
                statsEl.textContent = `${lines} lines, ${words} words, ${chars} characters`;
            }
        }

        // Clean up modal when closed
        modal.addEventListener('hidden.bs.modal', () => {
            modal.remove();
        });
    }

    renderCodePreview(container, content, filePath) {
        const lines = content.split('\n');
        const extension = getFileExtension(filePath.split('/').pop());

        // Create the code preview structure with synchronized scrolling
        container.innerHTML = `
            <div class="code-scroll-container">
                <div class="line-numbers-container">
                    <div class="line-numbers-scroll">
                        ${lines.map((_, index) => `<div class="line-number">${index + 1}</div>`).join('')}
                    </div>
                </div>
                <div class="code-content-container">
                    <pre class="code-text" data-language="${extension}"><code>${this.escapeHtml(content)}</code></pre>
                </div>
            </div>
        `;

        // Set up synchronized scrolling
        this.setupSynchronizedScrolling(container);
    }

    setupSynchronizedScrolling(container) {
        const lineNumbersContainer = container.querySelector('.line-numbers-container');
        const codeContentContainer = container.querySelector('.code-content-container');
        const lineNumbersScroll = container.querySelector('.line-numbers-scroll');

        if (!lineNumbersContainer || !codeContentContainer || !lineNumbersScroll) {
            return;
        }

        // Synchronize scrolling between code content and line numbers
        codeContentContainer.addEventListener('scroll', () => {
            const scrollTop = codeContentContainer.scrollTop;
            lineNumbersContainer.scrollTop = scrollTop;
        });

        // Optional: Allow scrolling from line numbers to affect code content
        lineNumbersContainer.addEventListener('scroll', () => {
            const scrollTop = lineNumbersContainer.scrollTop;
            codeContentContainer.scrollTop = scrollTop;
        });

        // Ensure line numbers container can scroll
        lineNumbersContainer.style.overflow = 'hidden';
        lineNumbersContainer.style.height = '100%';

        // Make sure the line numbers scroll area matches the code content height
        const codeText = container.querySelector('.code-text');
        if (codeText) {
            const codeHeight = codeText.scrollHeight;
            lineNumbersScroll.style.height = `${codeHeight}px`;
        }
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    copyModalContent() {
        const contentEl = el('modalPreviewContent');
        if (!contentEl) {
            console.warn('Modal content element not found');
            return;
        }

        const textContent = contentEl.textContent;
        if (!textContent || textContent.trim().length === 0) {
            console.warn('No content to copy');
            return;
        }

        if (!navigator.clipboard) {
            // Fallback for older browsers
            this.fallbackCopyToClipboard(textContent);
            return;
        }

        navigator.clipboard.writeText(textContent).then(() => {
            // Show success feedback
            const originalContent = contentEl.innerHTML;
            contentEl.innerHTML = '<div class="success-message">Content copied to clipboard!</div>';
            setTimeout(() => {
                contentEl.innerHTML = originalContent;
            }, 2000);
        }).catch(err => {
            console.error('Failed to copy content:', err);
            contentEl.innerHTML = '<div class="error-message">Failed to copy content</div>';
            setTimeout(() => {
                contentEl.innerHTML = originalContent;
            }, 2000);
        });
    }

    fallbackCopyToClipboard(text) {
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.left = '-999999px';
        textArea.style.top = '-999999px';
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            document.execCommand('copy');
            console.log('Fallback: Content copied to clipboard');
        } catch (err) {
            console.error('Fallback: Failed to copy content', err);
        }

        document.body.removeChild(textArea);
    }

    removeFromSelection(path) {
        selected.delete(path);

        // Update checkbox
        const checkbox = qs(`[data-path="${path}"] .tree-checkbox`);
        if (checkbox) {
            checkbox.checked = false;
        }

        this.updateSelectionUI();
    }

    selectAll() {
        qsa('.tree-checkbox').forEach(checkbox => {
            checkbox.checked = true;
            const path = checkbox.closest('.tree-item').dataset.path;
            selected.add(path);
        });
        this.updateSelectionUI();
    }

    clearSelection() {
        selected.clear();
        qsa('.tree-checkbox').forEach(checkbox => {
            checkbox.checked = false;
        });
        this.updateSelectionUI();
    }

    collapseAll() {
        expandedDirs.clear();
        qsa('.tree-expand-btn').forEach(btn => {
            btn.innerHTML = '▶';
        });
        // Remove all children except root level
        qsa('.tree-item').forEach(item => {
            const depth = parseInt(item.style.paddingLeft) / 16;
            if (depth > 0) {
                item.remove();
            }
        });
        this.loadedPaths.clear();
    }

    async search(query) {
        searchQuery = query.toLowerCase().trim();

        if (!searchQuery) {
            // Show all items when search is cleared
            qsa('.tree-item').forEach(item => {
                item.style.display = 'block';
            });
            return;
        }

        try {
            // Use the new search API to get all matching files across the workspace
            const searchResults = await api(`/api/heroprompt/workspaces/${encodeURIComponent(currentWs)}/search?q=${encodeURIComponent(searchQuery)}`);

            if (searchResults.error) {
                console.warn('Search failed:', searchResults.error);
                // Fallback to local search
                this.localSearch(query);
                return;
            }

            // Hide all current items
            qsa('.tree-item').forEach(item => {
                item.style.display = 'none';
            });

            // Show matching items and expand their parent directories
            const matchingPaths = new Set();
            searchResults.results.forEach(result => {
                matchingPaths.add(result.path);
                // Also add parent directory paths
                const pathParts = result.path.split('/');
                for (let i = 1; i < pathParts.length; i++) {
                    const parentPath = pathParts.slice(0, i).join('/');
                    if (parentPath) {
                        matchingPaths.add(parentPath);
                    }
                }
            });

            // Show items that match or are parents of matches
            // Get workspace info once
            const workspaceInfo = await api(`/api/heroprompt/workspaces/${currentWs}`);

            qsa('.tree-item').forEach(item => {
                const itemPath = item.dataset.path;
                if (itemPath) {
                    // Get relative path from workspace base
                    let relPath = itemPath;
                    if (workspaceInfo && workspaceInfo.base_path && itemPath.startsWith(workspaceInfo.base_path)) {
                        relPath = itemPath.substring(workspaceInfo.base_path.length);
                        if (relPath.startsWith('/')) {
                            relPath = relPath.substring(1);
                        }
                    }

                    if (matchingPaths.has(relPath) || relPath === '') {
                        item.style.display = 'block';
                        // Auto-expand directories that contain matches
                        if (item.dataset.type === 'directory' && !this.expandedDirs.has(itemPath)) {
                            this.toggleDirectory(itemPath);
                        }
                    }
                }
            });

        } catch (error) {
            console.warn('Search API error:', error);
            // Fallback to local search
            this.localSearch(query);
        }
    }

    localSearch(query) {
        const searchQuery = query.toLowerCase();
        qsa('.tree-item').forEach(item => {
            const label = item.querySelector('.tree-label');
            if (label) {
                const matches = !searchQuery || label.textContent.toLowerCase().includes(searchQuery);
                item.style.display = matches ? 'block' : 'none';
            }
        });
    }

    async render(workspacePath) {
        this.container.innerHTML = '<div class="loading">Loading workspace...</div>';

        const r = await api(`/api/heroprompt/directory?name=${currentWs}&path=${encodeURIComponent(workspacePath)}`);

        if (r.error) {
            this.container.innerHTML = `<div class="error-message">${r.error}</div>`;
            return;
        }

        // Reset state
        this.loadedPaths.clear();
        this.expandedDirs.clear();
        expandedDirs.clear();

        // Sort items: directories first, then files
        const items = (r.items || []).sort((a, b) => {
            if (a.type !== b.type) {
                return a.type === 'directory' ? -1 : 1;
            }
            return a.name.localeCompare(b.name);
        });

        // Create document fragment for efficient DOM manipulation
        const fragment = document.createDocumentFragment();
        const elements = [];

        // Create all elements first
        for (const item of items) {
            const fullPath = workspacePath.endsWith('/') ?
                workspacePath + item.name :
                workspacePath + '/' + item.name;

            const element = this.createFileItem(item, fullPath, 0);
            element.style.opacity = '0';
            element.style.transform = 'translateY(-10px)';
            element.style.transition = 'opacity 0.3s ease, transform 0.3s ease';

            fragment.appendChild(element);
            elements.push(element);
        }

        // Clear container and add all elements at once
        this.container.innerHTML = '';
        this.container.appendChild(fragment);

        // Trigger staggered animations
        elements.forEach((element, i) => {
            setTimeout(() => {
                element.style.opacity = '1';
                element.style.transform = 'translateY(0)';
            }, i * 50);
        });

        this.updateSelectionUI();
    }

    async renderWorkspaceDirectories(directories) {
        this.container.innerHTML = '<div class="loading">Loading workspace directories...</div>';

        // Reset state
        this.loadedPaths.clear();
        this.expandedDirs.clear();
        expandedDirs.clear();

        if (!directories || directories.length === 0) {
            this.container.innerHTML = `
                <div class="empty-state">
                    <i class="icon-folder-open"></i>
                    <p>No directories added yet</p>
                    <small>Use the "Add Dir" button to add directories to this workspace</small>
                </div>
            `;
            return;
        }

        // Create document fragment for efficient DOM manipulation
        const fragment = document.createDocumentFragment();
        const elements = [];

        // Create elements for each workspace directory
        for (const dir of directories) {
            if (!dir.path || dir.path.cat !== 'dir') continue;

            const dirPath = dir.path.path;
            const dirName = dir.name || dirPath.split('/').pop();

            // Create a directory item that can be expanded
            const item = {
                name: dirName,
                type: 'directory'
            };

            const element = this.createFileItem(item, dirPath, 0);
            element.style.opacity = '0';
            element.style.transform = 'translateY(-10px)';
            element.style.transition = 'opacity 0.3s ease, transform 0.3s ease';

            fragment.appendChild(element);
            elements.push(element);
        }

        // Clear container and add all elements at once
        this.container.innerHTML = '';
        this.container.appendChild(fragment);

        // Trigger staggered animations
        elements.forEach((element, i) => {
            setTimeout(() => {
                element.style.opacity = '1';
                element.style.transform = 'translateY(0)';
            }, i * 50);
        });

        this.updateSelectionUI();
    }
}

// Global tree instance
let fileTree = null;

// Workspace management
async function reloadWorkspaces() {
    const sel = el('workspaceSelect');
    if (!sel) return;

    sel.innerHTML = '<option>Loading...</option>';
    const names = await api('/api/heroprompt/workspaces');

    sel.innerHTML = '';
    if (names.error || !Array.isArray(names)) {
        sel.innerHTML = '<option>Error loading workspaces</option>';
        console.warn('Failed to load workspaces:', names);
        return;
    }

    for (const n of names) {
        const opt = document.createElement('option');
        opt.value = n;
        opt.textContent = n;
        sel.appendChild(opt);
    }

    if (names.includes(currentWs)) {
        sel.value = currentWs;
    } else if (names.length > 0) {
        currentWs = names[0];
        sel.value = currentWs;
        localStorage.setItem('heroprompt-current-ws', currentWs);
    }
}

async function initWorkspace() {
    const names = await api('/api/heroprompt/workspaces');
    if (names.error || !Array.isArray(names) || names.length === 0) {
        console.warn('No workspaces available');
        const treeEl = el('tree');
        if (treeEl) {
            treeEl.innerHTML = `
                <div class="empty-state">
                    <i class="icon-folder-open"></i>
                    <p>No workspaces available</p>
                    <small>Create one to get started</small>
                </div>
            `;
        }
        return;
    }

    if (!currentWs || !names.includes(currentWs)) {
        currentWs = names[0];
        localStorage.setItem('heroprompt-current-ws', currentWs);
    }

    const sel = el('workspaceSelect');
    if (sel) sel.value = currentWs;

    // Load and display workspace directories
    await loadWorkspaceDirectories();
}

async function loadWorkspaceDirectories() {
    const treeEl = el('tree');
    if (!treeEl) return;

    try {
        const children = await api(`/api/heroprompt/workspaces/${currentWs}/children`);

        if (children.error) {
            console.warn('Failed to load workspace children:', children.error);
            treeEl.innerHTML = `
                <div class="empty-state">
                    <i class="icon-folder-open"></i>
                    <p>No directories added yet</p>
                    <small>Use the "Add Dir" button to add directories to this workspace</small>
                </div>
            `;
            return;
        }

        // Filter only directories
        const directories = children.filter(child => child.path && child.path.cat === 'dir');

        if (directories.length === 0) {
            treeEl.innerHTML = `
                <div class="empty-state">
                    <i class="icon-folder-open"></i>
                    <p>No directories added yet</p>
                    <small>Use the "Add Dir" button to add directories to this workspace</small>
                </div>
            `;
            return;
        }

        // Create file tree with workspace directories as roots
        if (fileTree) {
            await fileTree.renderWorkspaceDirectories(directories);
        }
    } catch (error) {
        console.error('Error loading workspace directories:', error);
        treeEl.innerHTML = `
            <div class="empty-state">
                <i class="icon-folder-open"></i>
                <p>Error loading directories</p>
                <small>Please try refreshing the page</small>
            </div>
        `;
    }
}

// Prompt generation
async function generatePrompt() {
    const promptTextEl = el('promptText');
    const outputEl = el('promptOutput');

    if (!outputEl) {
        console.error('Prompt output element not found');
        return;
    }

    if (!currentWs) {
        outputEl.innerHTML = '<div class="error-message">No workspace selected. Please select a workspace first.</div>';
        return;
    }

    if (selected.size === 0) {
        outputEl.innerHTML = '<div class="error-message">No files selected. Please select files first.</div>';
        return;
    }

    const promptText = promptTextEl?.value?.trim() || '';
    outputEl.innerHTML = '<div class="loading">Generating prompt...</div>';

    try {
        // Pass selections directly to prompt generation
        const paths = Array.from(selected);
        const formData = new URLSearchParams();
        formData.append('text', promptText);
        formData.append('selected_paths', JSON.stringify(paths));

        const r = await fetch(`/api/heroprompt/workspaces/${encodeURIComponent(currentWs)}/prompt`, {
            method: 'POST',
            body: formData
        });

        if (!r.ok) {
            throw new Error(`HTTP ${r.status}: ${r.statusText}`);
        }

        const result = await r.text();
        if (result.trim().length === 0) {
            outputEl.innerHTML = '<div class="error-message">Generated prompt is empty</div>';
        } else {
            outputEl.textContent = result;
        }
    } catch (e) {
        console.warn('Generate prompt failed', e);
        outputEl.innerHTML = `<div class="error-message">Failed to generate prompt: ${e.message}</div>`;
    }
}

async function copyPrompt() {
    const outputEl = el('promptOutput');
    if (!outputEl) {
        console.warn('Prompt output element not found');
        showStatus('Copy failed - element not found', 'error');
        return;
    }

    // Grab the visible prompt text, stripping HTML and empty-state placeholders
    const text = outputEl.innerText.trim();
    if (!text || text.includes('Generated prompt will appear here') || text.includes('No files selected')) {
        showStatus('Nothing to copy', 'warning');
        return;
    }

    // Try the modern Clipboard API first
    if (navigator.clipboard && navigator.clipboard.writeText) {
        try {
            await navigator.clipboard.writeText(text);
            showStatus('Prompt copied to clipboard!', 'success');
            return;
        } catch (e) {
            console.warn('Clipboard API failed, falling back', e);
        }
    }

    // Fallback to hidden textarea method
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';   // avoid scrolling to bottom
    textarea.style.left = '-9999px';
    document.body.appendChild(textarea);
    textarea.focus();
    textarea.select();

    try {
        const successful = document.execCommand('copy');
        showStatus(successful ? 'Prompt copied!' : 'Copy failed', successful ? 'success' : 'error');
    } catch (e) {
        console.error('Fallback copy failed', e);
        showStatus('Copy failed', 'error');
    } finally {
        document.body.removeChild(textarea);
    }
}

/* Helper – show a transient message inside the output pane */
function showStatus(msg, type = 'info') {
    const out = el('promptOutput');
    if (!out) return;

    const original = out.innerHTML;
    const statusClass = type === 'success' ? 'success-message' :
        type === 'error' ? 'error-message' :
            type === 'warning' ? 'warning-message' : 'info-message';

    out.innerHTML = `<div class="${statusClass}">${msg}</div>`;
    setTimeout(() => {
        out.innerHTML = original;
    }, 2000);
}

// Global fallback function for clipboard operations
function fallbackCopyToClipboard(text) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
        document.execCommand('copy');
        console.log('Fallback: Content copied to clipboard');
    } catch (err) {
        console.error('Fallback: Failed to copy content', err);
    }

    document.body.removeChild(textArea);
}

// Confirmation modal helper
function showConfirmationModal(message, onConfirm) {
    const messageEl = el('confirmDeleteMessage');
    const confirmBtn = el('confirmDeleteBtn');

    if (messageEl) messageEl.textContent = message;

    // Remove any existing event listeners
    const newConfirmBtn = confirmBtn.cloneNode(true);
    confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);

    // Add new event listener
    newConfirmBtn.addEventListener('click', () => {
        hideModal('confirmDeleteModal');
        onConfirm();
    });

    showModal('confirmDeleteModal');
}

// Workspace management functions
async function deleteWorkspace(workspaceName) {
    try {
        const encodedName = encodeURIComponent(workspaceName);
        const response = await fetch(`/api/heroprompt/workspaces/${encodedName}/delete`, {
            method: 'POST'
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Delete failed:', response.status, errorText);
            throw new Error(`HTTP ${response.status}: ${errorText}`);
        }

        // If we deleted the current workspace, switch to another one
        if (workspaceName === currentWs) {
            const names = await api('/api/heroprompt/workspaces');
            if (names && Array.isArray(names) && names.length > 0) {
                currentWs = names[0];
                localStorage.setItem('heroprompt-current-ws', currentWs);
                await reloadWorkspaces();

                // Load directories for new current workspace
                await loadWorkspaceDirectories();
            }
        }

        return { success: true };
    } catch (e) {
        console.warn('Delete workspace failed', e);
        return { error: 'Failed to delete workspace' };
    }
}

async function updateWorkspace(workspaceName, newName) {
    try {
        const formData = new FormData();
        if (newName && newName !== workspaceName) {
            formData.append('name', newName);
        }

        const encodedName = encodeURIComponent(workspaceName);
        const response = await fetch(`/api/heroprompt/workspaces/${encodedName}`, {
            method: 'PUT',
            body: formData
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error('Update failed:', response.status, errorText);
            throw new Error(`HTTP ${response.status}: ${errorText}`);
        }

        const result = await response.json();

        // Update current workspace if it was renamed
        if (workspaceName === currentWs && result.name && result.name !== workspaceName) {
            currentWs = result.name;
            localStorage.setItem('heroprompt-current-ws', currentWs);
        }

        await reloadWorkspaces();
        return result;
    } catch (e) {
        console.warn('Update workspace failed', e);
        return { error: 'Failed to update workspace' };
    }
}

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
    // Initialize file tree
    const treeContainer = el('tree');
    if (treeContainer) {
        fileTree = new SimpleFileTree(treeContainer);
    }

    // Initialize workspaces
    initWorkspace();
    reloadWorkspaces();

    // Tab switching
    qsa('.tab').forEach(tab => {
        tab.addEventListener('click', function (e) {
            e.preventDefault();
            const tabName = this.getAttribute('data-tab');
            switchTab(tabName);
        });
    });

    // Workspace selector
    const workspaceSelect = el('workspaceSelect');
    if (workspaceSelect) {
        workspaceSelect.addEventListener('change', async (e) => {
            currentWs = e.target.value;
            localStorage.setItem('heroprompt-current-ws', currentWs);

            // Load directories for the new workspace
            await loadWorkspaceDirectories();
        });
    }

    // Explorer controls
    const collapseAllBtn = el('collapseAll');
    if (collapseAllBtn) {
        collapseAllBtn.addEventListener('click', () => {
            if (fileTree) fileTree.collapseAll();
        });
    }

    const refreshExplorerBtn = el('refreshExplorer');
    if (refreshExplorerBtn) {
        refreshExplorerBtn.addEventListener('click', async () => {
            // Reload workspace directories
            await loadWorkspaceDirectories();
        });
    }

    const selectAllBtn = el('selectAll');
    if (selectAllBtn) {
        selectAllBtn.addEventListener('click', () => {
            if (fileTree) fileTree.selectAll();
        });
    }

    const clearSelectionBtn = el('clearSelection');
    if (clearSelectionBtn) {
        clearSelectionBtn.addEventListener('click', () => {
            if (fileTree) fileTree.clearSelection();
        });
    }

    const clearAllSelectionBtn = el('clearAllSelection');
    if (clearAllSelectionBtn) {
        clearAllSelectionBtn.addEventListener('click', () => {
            if (fileTree) fileTree.clearSelection();
        });
    }

    // Search functionality
    const searchInput = el('search');
    const clearSearchBtn = el('clearSearch');

    if (searchInput) {
        searchInput.addEventListener('input', (e) => {
            if (fileTree) {
                fileTree.search(e.target.value);
            }
        });
    }

    if (clearSearchBtn) {
        clearSearchBtn.addEventListener('click', () => {
            if (searchInput) {
                searchInput.value = '';
                if (fileTree) {
                    fileTree.search('');
                }
            }
        });
    }

    // Prompt generation
    const generatePromptBtn = el('generatePrompt');
    if (generatePromptBtn) {
        generatePromptBtn.addEventListener('click', generatePrompt);
    }

    const copyPromptBtn = el('copyPrompt');
    if (copyPromptBtn) {
        copyPromptBtn.addEventListener('click', copyPrompt);
    }

    // Workspace creation modal
    const wsCreateBtn = el('wsCreateBtn');
    if (wsCreateBtn) {
        wsCreateBtn.addEventListener('click', () => {
            const nameEl = el('wcName');
            const errorEl = el('wcError');

            if (nameEl) nameEl.value = '';
            if (errorEl) errorEl.textContent = '';

            showModal('wsCreate');
        });
    }

    const wcCreateBtn = el('wcCreate');
    if (wcCreateBtn) {
        wcCreateBtn.addEventListener('click', async () => {
            const name = el('wcName')?.value?.trim() || '';
            const errorEl = el('wcError');

            if (!name) {
                if (errorEl) errorEl.textContent = 'Workspace name is required.';
                return;
            }

            const formData = { name: name };

            const resp = await post('/api/heroprompt/workspaces', formData);
            if (resp.error) {
                if (errorEl) errorEl.textContent = resp.error;
                return;
            }

            currentWs = resp.name || currentWs;
            localStorage.setItem('heroprompt-current-ws', currentWs);
            await reloadWorkspaces();

            // Clear the file tree since new workspace has no directories yet
            if (fileTree) {
                const treeEl = el('tree');
                if (treeEl) {
                    treeEl.innerHTML = `
                        <div class="empty-state">
                            <i class="icon-folder-open"></i>
                            <p>No directories added yet</p>
                            <small>Use the "Add Dir" button to add directories to this workspace</small>
                        </div>
                    `;
                }
            }

            hideModal('wsCreate');
        });
    }

    // Workspace details modal
    const wsDetailsBtn = el('wsDetailsBtn');
    if (wsDetailsBtn) {
        wsDetailsBtn.addEventListener('click', async () => {
            const info = await api(`/api/heroprompt/workspaces/${currentWs}`);
            if (info && !info.error) {
                const nameEl = el('wdName');
                const errorEl = el('wdError');

                if (nameEl) nameEl.value = info.name || currentWs;
                if (errorEl) errorEl.textContent = '';

                showModal('wsDetails');
            }
        });
    }

    // Workspace details update
    const wdUpdateBtn = el('wdUpdate');
    if (wdUpdateBtn) {
        wdUpdateBtn.addEventListener('click', async () => {
            const name = el('wdName')?.value?.trim() || '';
            const errorEl = el('wdError');

            if (!name) {
                if (errorEl) errorEl.textContent = 'Workspace name is required.';
                return;
            }

            const result = await updateWorkspace(currentWs, name);
            if (result.error) {
                if (errorEl) errorEl.textContent = result.error;
                return;
            }

            hideModal('wsDetails');
        });
    }

    // Workspace details delete
    const wdDeleteBtn = el('wdDelete');
    if (wdDeleteBtn) {
        wdDeleteBtn.addEventListener('click', async () => {
            showConfirmationModal(`Are you sure you want to delete workspace "${currentWs}"?`, async () => {
                const result = await deleteWorkspace(currentWs);
                if (result.error) {
                    const errorEl = el('wdError');
                    if (errorEl) errorEl.textContent = result.error;
                    return;
                }
                hideModal('wsDetails');
            });
        });
    }

    // Add Directory functionality
    const addDirBtn = el('addDirBtn');
    if (addDirBtn) {
        addDirBtn.addEventListener('click', () => {
            const pathEl = el('addDirPath');
            const errorEl = el('addDirError');

            if (pathEl) pathEl.value = '';
            if (errorEl) errorEl.textContent = '';

            showModal('addDirModal');
        });
    }

    const addDirConfirm = el('addDirConfirm');
    if (addDirConfirm) {
        addDirConfirm.addEventListener('click', async () => {
            const path = el('addDirPath')?.value?.trim() || '';
            const errorEl = el('addDirError');

            if (!path) {
                if (errorEl) errorEl.textContent = 'Directory path is required.';
                return;
            }

            // Add directory via API
            const result = await post(`/api/heroprompt/workspaces/${encodeURIComponent(currentWs)}/dirs`, {
                path: path
            });

            if (result.error) {
                if (errorEl) errorEl.textContent = result.error;
                return;
            }

            // Success - close modal and refresh the file tree
            hideModal('addDirModal');

            // Reload workspace directories to show the newly added directory
            await loadWorkspaceDirectories();

            // Show success message
            showStatus('Directory added successfully!', 'success');
        });
    }

    // Chat functionality
    initChatInterface();
});

// Chat Interface Implementation
function initChatInterface() {
    const chatInput = el('chatInput');
    const sendBtn = el('sendChat');
    const messagesContainer = el('chatMessages');
    const charCount = el('charCount');
    const chatStatus = el('chatStatus');
    const typingIndicator = el('typingIndicator');
    const newChatBtn = el('newChatBtn');
    const chatList = el('chatList');

    let chatHistory = [];
    let isTyping = false;
    let conversations = JSON.parse(localStorage.getItem('heroprompt-conversations') || '[]');
    let currentConversationId = null;

    // Initialize chat input functionality
    if (chatInput && sendBtn) {
        // Auto-resize textarea
        chatInput.addEventListener('input', function () {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 120) + 'px';

            // Update character count
            if (charCount) {
                const count = this.value.length;
                charCount.textContent = count;
                charCount.className = 'char-count';
                if (count > 2000) charCount.classList.add('warning');
                if (count > 4000) charCount.classList.add('error');
            }

            // Enable/disable send button
            sendBtn.disabled = this.value.trim().length === 0;
        });

        // Handle Enter key
        chatInput.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                if (!sendBtn.disabled) {
                    sendMessage();
                }
            }
        });

        // Send button click
        sendBtn.addEventListener('click', sendMessage);
    }

    // Chat action buttons
    const clearChatBtn = el('clearChat');
    const exportChatBtn = el('exportChat');

    if (newChatBtn) {
        newChatBtn.addEventListener('click', startNewChat);
    }

    if (clearChatBtn) {
        clearChatBtn.addEventListener('click', clearChat);
    }

    if (exportChatBtn) {
        exportChatBtn.addEventListener('click', exportChat);
    }

    async function sendMessage() {
        const message = chatInput.value.trim();
        if (!message || isTyping) return;

        // Add user message to chat
        addMessage('user', message);
        chatInput.value = '';
        chatInput.style.height = 'auto';
        sendBtn.disabled = true;
        if (charCount) charCount.textContent = '0';

        // Show typing indicator
        showTypingIndicator();
        updateChatStatus('typing', 'AI is thinking...');

        try {
            // Simulate API call - replace with actual API endpoint
            const response = await simulateAIResponse(message);

            // Hide typing indicator
            hideTypingIndicator();

            // Add AI response
            addMessage('assistant', response);
            updateChatStatus('ready', 'Ready');

        } catch (error) {
            hideTypingIndicator();
            addMessage('assistant', 'Sorry, I encountered an error. Please try again.');
            updateChatStatus('error', 'Error occurred');
            console.error('Chat error:', error);
        }
    }

    function addMessage(role, content) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `chat-message ${role}`;

        const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const messageId = `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

        messageDiv.innerHTML = `
            <div class="message-avatar ${role}">
                <i class="icon-${role === 'user' ? 'user' : 'ai'}"></i>
            </div>
            <div class="message-content">
                <div class="message-text">${formatMessageContent(content)}</div>
                <div class="message-meta">
                    <span class="message-time">${timestamp}</span>
                    <div class="message-actions">
                        <button class="message-action" onclick="copyMessage('${messageId}')" title="Copy">
                            <i class="icon-copy"></i>
                        </button>
                        ${role === 'assistant' ? `
                        <button class="message-action" onclick="regenerateMessage('${messageId}')" title="Regenerate">
                            <i class="icon-regenerate"></i>
                        </button>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;

        messageDiv.id = messageId;

        // Remove welcome message if it exists
        const welcomeMessage = messagesContainer.querySelector('.welcome-message');
        if (welcomeMessage) {
            welcomeMessage.remove();
        }

        messagesContainer.appendChild(messageDiv);

        // Store in chat history
        chatHistory.push({
            id: messageId,
            role: role,
            content: content,
            timestamp: new Date().toISOString()
        });

        // Save to conversation
        if (window.saveMessageToConversation) {
            window.saveMessageToConversation(role, content);
        }

        // Auto-scroll to bottom
        scrollToBottom();
    }

    function formatMessageContent(content) {
        // Basic markdown-like formatting
        let formatted = content
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/`([^`]+)`/g, '<code>$1</code>')
            .replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
            .replace(/\n/g, '<br>');

        return formatted;
    }

    function showTypingIndicator() {
        if (typingIndicator) {
            typingIndicator.style.display = 'flex';
            isTyping = true;
        }
    }

    function hideTypingIndicator() {
        if (typingIndicator) {
            typingIndicator.style.display = 'none';
            isTyping = false;
        }
    }

    function updateChatStatus(type, message) {
        if (chatStatus) {
            chatStatus.textContent = message;
            chatStatus.className = `chat-status ${type}`;
        }
    }

    function scrollToBottom() {
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
    }

    function startNewChat() {
        clearChat();
        addMessage('assistant', 'Hello! I\'m ready to help you with your code. What would you like to know?');
    }

    function clearChat() {
        chatHistory = [];
        if (messagesContainer) {
            messagesContainer.innerHTML = `
                <div class="welcome-message">
                    <div class="welcome-avatar">
                        <i class="icon-ai"></i>
                    </div>
                    <div class="welcome-content">
                        <h4>Welcome to AI Assistant</h4>
                        <p>I'm here to help you with your code! You can:</p>
                        <ul>
                            <li>Ask questions about your selected files</li>
                            <li>Request code explanations and improvements</li>
                            <li>Get suggestions for best practices</li>
                            <li>Debug issues and optimize performance</li>
                        </ul>
                        <small>Select some files from the explorer and start chatting!</small>
                    </div>
                </div>
            `;
        }
        updateChatStatus('ready', 'Ready');
    }

    function exportChat() {
        if (chatHistory.length === 0) {
            alert('No chat history to export');
            return;
        }

        const exportData = {
            timestamp: new Date().toISOString(),
            messages: chatHistory,
            workspace: currentWs,
            selectedFiles: Array.from(selected)
        };

        const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `chat-export-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    // Simulate AI response - replace with actual API call
    async function simulateAIResponse(userMessage) {
        // Simulate network delay
        await new Promise(resolve => setTimeout(resolve, 1000 + Math.random() * 2000));

        // Get context from selected files
        const context = selected.size > 0 ?
            `Based on your selected files (${Array.from(selected).join(', ')}), ` : '';

        // Simple response generation - replace with actual AI API
        const responses = [
            `${context}I can help you analyze and improve your code. What specific aspect would you like me to focus on?`,
            `${context}I notice you're working with these files. Would you like me to review the code structure or suggest improvements?`,
            `${context}I can help explain the code, identify potential issues, or suggest optimizations. What would you like to know?`,
            `${context}Let me analyze your code and provide insights. Is there a particular functionality you'd like me to examine?`
        ];

        if (userMessage.toLowerCase().includes('error') || userMessage.toLowerCase().includes('bug')) {
            return `${context}I can help you debug issues. Please share the specific error message or describe the unexpected behavior you're experiencing.`;
        }

        if (userMessage.toLowerCase().includes('optimize') || userMessage.toLowerCase().includes('performance')) {
            return `${context}For performance optimization, I can analyze your code for bottlenecks, suggest algorithmic improvements, and recommend best practices.`;
        }

        if (userMessage.toLowerCase().includes('explain') || userMessage.toLowerCase().includes('how')) {
            return `${context}I'd be happy to explain the code functionality. Which specific part would you like me to break down?`;
        }

        return responses[Math.floor(Math.random() * responses.length)];
    }
}

// Global helper function for message formatting
function formatMessageContent(content) {
    // Basic markdown-like formatting
    let formatted = content
        .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
        .replace(/\*(.*?)\*/g, '<em>$1</em>')
        .replace(/`([^`]+)`/g, '<code>$1</code>')
        .replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
        .replace(/\n/g, '<br>');

    return formatted;
}

// Global functions for message actions
function copyMessage(messageId) {
    const messageEl = document.getElementById(messageId);
    if (!messageEl) return;

    const textEl = messageEl.querySelector('.message-text');
    if (!textEl) return;

    const text = textEl.textContent || textEl.innerText;

    if (navigator.clipboard) {
        navigator.clipboard.writeText(text).then(() => {
            showMessageFeedback(messageId, 'Copied!');
        }).catch(err => {
            console.error('Copy failed:', err);
            fallbackCopyToClipboard(text);
        });
    } else {
        fallbackCopyToClipboard(text);
    }
}

function regenerateMessage(messageId) {
    const messageEl = document.getElementById(messageId);
    if (!messageEl) return;

    // Find the previous user message
    let prevMessage = messageEl.previousElementSibling;
    while (prevMessage && !prevMessage.classList.contains('user')) {
        prevMessage = prevMessage.previousElementSibling;
    }

    if (prevMessage) {
        const userText = prevMessage.querySelector('.message-text').textContent;

        // Remove the current AI message
        messageEl.remove();

        // Show typing indicator and regenerate
        const typingIndicator = el('typingIndicator');
        if (typingIndicator) {
            typingIndicator.style.display = 'flex';
        }

        // Simulate regeneration
        setTimeout(async () => {
            try {
                const response = await simulateAIResponse(userText);
                if (typingIndicator) {
                    typingIndicator.style.display = 'none';
                }

                // Create a new message manually
                const messageDiv = document.createElement('div');
                messageDiv.className = 'chat-message assistant';
                const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                const newMessageId = `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

                messageDiv.innerHTML = `
                    <div class="message-avatar assistant">
                        <i class="icon-ai"></i>
                    </div>
                    <div class="message-content">
                        <div class="message-text">${formatMessageContent(response)}</div>
                        <div class="message-meta">
                            <span class="message-time">${timestamp}</span>
                            <div class="message-actions">
                                <button class="message-action" onclick="copyMessage('${newMessageId}')" title="Copy">
                                    <i class="icon-copy"></i>
                                </button>
                                <button class="message-action" onclick="regenerateMessage('${newMessageId}')" title="Regenerate">
                                    <i class="icon-regenerate"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                `;

                messageDiv.id = newMessageId;
                const messagesContainer = el('chatMessages');
                if (messagesContainer) {
                    messagesContainer.appendChild(messageDiv);
                    messagesContainer.scrollTop = messagesContainer.scrollHeight;
                }
            } catch (error) {
                if (typingIndicator) {
                    typingIndicator.style.display = 'none';
                }
                console.error('Regeneration error:', error);
            }
        }, 1500);
    }
}

function showMessageFeedback(messageId, text) {
    const messageEl = document.getElementById(messageId);
    if (!messageEl) return;

    const actionsEl = messageEl.querySelector('.message-actions');
    if (!actionsEl) return;

    const originalHTML = actionsEl.innerHTML;
    actionsEl.innerHTML = `<span style="color: var(--success-color); font-size: 11px;">${text}</span>`;

    setTimeout(() => {
        actionsEl.innerHTML = originalHTML;
    }, 2000);
}

// Chat List Management Functions
function initChatList() {
    const chatList = el('chatList');
    const newChatBtn = el('newChatBtn');

    if (!chatList) return;

    let conversations = JSON.parse(localStorage.getItem('heroprompt-conversations') || '[]');
    let currentConversationId = localStorage.getItem('heroprompt-current-conversation') || null;

    function renderChatList() {
        if (conversations.length === 0) {
            chatList.innerHTML = `
                <div class="empty-chat-list">
                    <i class="icon-chat"></i>
                    <p>No conversations yet</p>
                    <small>Start a new chat to begin</small>
                </div>
            `;
            return;
        }

        const conversationsHtml = conversations.map(conv => {
            const isActive = conv.id === currentConversationId;
            const preview = conv.messages.length > 0 ?
                conv.messages[conv.messages.length - 1].content.substring(0, 50) + '...' :
                'New conversation';
            const time = new Date(conv.updatedAt).toLocaleDateString();

            return `
                <div class="chat-conversation-item ${isActive ? 'active' : ''}" data-conversation-id="${conv.id}">
                    <div class="conversation-title">${conv.title}</div>
                    <div class="conversation-preview">${preview}</div>
                    <div class="conversation-meta">
                        <span class="conversation-time">${time}</span>
                        <div class="conversation-actions">
                            <button class="conversation-action" onclick="deleteConversation('${conv.id}')" title="Delete">
                                <i class="icon-clear"></i>
                            </button>
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        chatList.innerHTML = `<div class="chat-conversations">${conversationsHtml}</div>`;

        // Add click listeners to conversation items
        chatList.querySelectorAll('.chat-conversation-item').forEach(item => {
            item.addEventListener('click', (e) => {
                if (!e.target.closest('.conversation-action')) {
                    const conversationId = item.dataset.conversationId;
                    loadConversation(conversationId);
                }
            });
        });
    }

    function createNewConversation() {
        const newConversation = {
            id: 'conv-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9),
            title: `Chat ${conversations.length + 1}`,
            messages: [],
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };

        conversations.unshift(newConversation);
        localStorage.setItem('heroprompt-conversations', JSON.stringify(conversations));
        loadConversation(newConversation.id);
        renderChatList();
    }

    function loadConversation(conversationId) {
        currentConversationId = conversationId;
        localStorage.setItem('heroprompt-current-conversation', conversationId);

        const messagesContainer = el('chatMessages');
        if (!messagesContainer) return;

        if (conversationId) {
            const conversation = conversations.find(c => c.id === conversationId);
            if (conversation && conversation.messages.length > 0) {
                // Load existing conversation
                messagesContainer.innerHTML = '';
                conversation.messages.forEach(message => {
                    addMessageToDOM(message.role, message.content, message.timestamp);
                });
            } else {
                // Show welcome message for empty conversation
                showWelcomeMessage();
            }
        } else {
            // New conversation
            showWelcomeMessage();
        }

        renderChatList(); // Update active state
        scrollToBottom();
    }

    function showWelcomeMessage() {
        const messagesContainer = el('chatMessages');
        if (!messagesContainer) return;

        messagesContainer.innerHTML = `
            <div class="welcome-message">
                <div class="welcome-avatar">
                    <i class="icon-ai"></i>
                </div>
                <div class="welcome-content">
                    <h4>Welcome to AI Assistant</h4>
                    <p>I'm here to help you with your code! You can:</p>
                    <ul>
                        <li>Ask questions about your selected files</li>
                        <li>Request code explanations and improvements</li>
                        <li>Get suggestions for best practices</li>
                        <li>Debug issues and optimize performance</li>
                    </ul>
                    <small>Select some files from the explorer and start chatting!</small>
                </div>
            </div>
        `;
    }

    function addMessageToDOM(role, content, timestamp) {
        const messagesContainer = el('chatMessages');
        if (!messagesContainer) return;

        const messageDiv = document.createElement('div');
        messageDiv.className = `chat-message ${role}`;

        const time = timestamp ? new Date(timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) :
            new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const messageId = `msg-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

        messageDiv.innerHTML = `
            <div class="message-avatar ${role}">
                <i class="icon-${role === 'user' ? 'user' : 'ai'}"></i>
            </div>
            <div class="message-content">
                <div class="message-text">${formatMessageContent(content)}</div>
                <div class="message-meta">
                    <span class="message-time">${time}</span>
                    <div class="message-actions">
                        <button class="message-action" onclick="copyMessage('${messageId}')" title="Copy">
                            <i class="icon-copy"></i>
                        </button>
                        ${role === 'assistant' ? `
                        <button class="message-action" onclick="regenerateMessage('${messageId}')" title="Regenerate">
                            <i class="icon-regenerate"></i>
                        </button>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;

        messageDiv.id = messageId;
        messagesContainer.appendChild(messageDiv);
    }

    function scrollToBottom() {
        const messagesContainer = el('chatMessages');
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
    }

    // Initialize
    renderChatList();
    if (currentConversationId) {
        loadConversation(currentConversationId);
    } else {
        showWelcomeMessage();
    }

    // Event listeners
    if (newChatBtn) {
        newChatBtn.addEventListener('click', createNewConversation);
    }

    // Expose functions globally
    window.loadConversation = loadConversation;
    window.deleteConversation = function (conversationId) {
        conversations = conversations.filter(c => c.id !== conversationId);
        localStorage.setItem('heroprompt-conversations', JSON.stringify(conversations));

        if (currentConversationId === conversationId) {
            currentConversationId = null;
            localStorage.removeItem('heroprompt-current-conversation');
            showWelcomeMessage();
        }

        renderChatList();
    };

    window.saveMessageToConversation = function (role, content) {
        if (!currentConversationId) {
            createNewConversation();
        }

        const conversation = conversations.find(c => c.id === currentConversationId);
        if (conversation) {
            const message = {
                role: role,
                content: content,
                timestamp: new Date().toISOString()
            };

            conversation.messages.push(message);
            conversation.updatedAt = new Date().toISOString();

            // Update title based on first user message
            if (role === 'user' && conversation.title.startsWith('Chat ')) {
                conversation.title = content.substring(0, 30) + '...';
            }

            localStorage.setItem('heroprompt-conversations', JSON.stringify(conversations));
            renderChatList();
        }
    };
}

// Initialize chat list when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
    // Add a small delay to ensure other initialization is complete
    setTimeout(() => {
        initChatList();
    }, 100);
});
