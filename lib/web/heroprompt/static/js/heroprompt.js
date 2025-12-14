/**
 * HeroPrompt - Code Context Tool
 * Client-side JavaScript for UI interactions
 */

(function () {
    'use strict';

    // ============================================
    // State Management
    // ============================================
    const state = {
        workspaces: [],
        activeWorkspaceId: '',
        activeRepoId: '',
        files: [],
        fileTree: {},  // File tree loaded from API
        selectedFiles: new Set(),
        expandedFolders: new Set(),
        theme: localStorage.getItem('heroprompt-theme') || 'light',
        sortBy: 'name', // name, path, size, tokens
        searchQuery: ''
    };

    // ============================================
    // DOM Elements
    // ============================================
    const elements = {
        // Header - Workspace
        workspaceSelect: document.getElementById('workspaceSelect'),
        newWorkspaceBtn: document.getElementById('newWorkspaceBtn'),
        renameWorkspaceBtn: document.getElementById('renameWorkspaceBtn'),
        deleteWorkspaceBtn: document.getElementById('deleteWorkspaceBtn'),
        addDirBtn: document.getElementById('addDirBtn'),
        themeToggle: document.getElementById('themeToggle'),
        totalTokens: document.getElementById('totalTokens'),

        // Workspace Sidebar
        workspaceTitle: document.getElementById('workspaceTitle'),
        repoList: document.getElementById('repoList'),
        workspaceSearch: document.getElementById('workspaceSearch'),
        clearSearchBtn: document.getElementById('clearSearchBtn'),

        // Prompt Panel
        promptInput: document.getElementById('promptInput'),
        clearPromptBtn: document.getElementById('clearPromptBtn'),
        generateBtn: document.getElementById('generateBtn'),
        copyAllBtn: document.getElementById('copyAllBtn'),
        promptTokens: document.getElementById('promptTokens'),

        // Selected Files Panel
        selectedFiles: document.getElementById('selectedFiles'),
        selectedFilesCount: document.getElementById('selectedFilesCount'),
        deselectAllBtn: document.getElementById('deselectAllBtn'),
        sortSelect: document.getElementById('sortSelect'),
        selectionTokens: document.getElementById('selectionTokens'),
        selectionSize: document.getElementById('selectionSize'),

        // Output Modal
        outputModal: document.getElementById('outputModal'),
        closeModalBtn: document.getElementById('closeModalBtn'),
        outputPreview: document.getElementById('outputPreview'),
        copyOutputBtn: document.getElementById('copyOutputBtn'),
        outputTokens: document.getElementById('outputTokens'),
        outputSize: document.getElementById('outputSize'),

        // Dialog Modal
        dialogModal: document.getElementById('dialogModal'),
        dialogTitle: document.getElementById('dialogTitle'),
        dialogBody: document.getElementById('dialogBody'),
        dialogCancelBtn: document.getElementById('dialogCancelBtn'),
        dialogConfirmBtn: document.getElementById('dialogConfirmBtn'),

        // Templates
        addDirDialogTemplate: document.getElementById('addDirDialogTemplate'),

        // Resize handles
        resizeHandle0: document.getElementById('resizeHandle0'),
        resizeHandle1: document.getElementById('resizeHandle1')
    };

    // ============================================
    // API Helpers
    // ============================================
    async function apiGet(url) {
        const response = await fetch(url);
        return response.json();
    }

    async function apiPost(url, data = {}) {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
        return response.json();
    }

    async function apiDelete(url) {
        const response = await fetch(url, { method: 'DELETE' });
        return response.json();
    }

    // ============================================
    // Dialog Management
    // ============================================
    let dialogConfirmCallback = null;
    let dialogCancelCallback = null;
    let isAlertMode = false;

    function showDialog(title, templateId, confirmText = 'Confirm', onConfirm = null, options = {}) {
        if (!elements.dialogModal) return;

        // Set title
        if (elements.dialogTitle) {
            elements.dialogTitle.textContent = title;
        }

        // Load template content
        const template = document.getElementById(templateId);
        if (template && elements.dialogBody) {
            elements.dialogBody.innerHTML = '';
            elements.dialogBody.appendChild(template.content.cloneNode(true));
        }

        // Set confirm button text
        if (elements.dialogConfirmBtn) {
            elements.dialogConfirmBtn.textContent = confirmText;
            elements.dialogConfirmBtn.className = options.confirmClass || 'btn btn-primary';
        }

        // Handle alert mode or showCancel option (hide cancel button)
        isAlertMode = options.alertMode || false;
        const hideCancel = isAlertMode || options.showCancel === false;
        if (elements.dialogCancelBtn) {
            elements.dialogCancelBtn.style.display = hideCancel ? 'none' : '';
        }

        // Store callbacks
        dialogConfirmCallback = onConfirm;
        dialogCancelCallback = options.onCancel || null;

        // Show modal
        elements.dialogModal.style.display = 'flex';
    }

    function hideDialog() {
        if (elements.dialogModal) {
            elements.dialogModal.style.display = 'none';
        }
        if (elements.dialogBody) {
            elements.dialogBody.innerHTML = '';
        }
        dialogConfirmCallback = null;
        dialogCancelCallback = null;
        isAlertMode = false;
    }

    function confirmDialog() {
        if (dialogConfirmCallback) {
            dialogConfirmCallback();
        }
        hideDialog();
    }

    function cancelDialog() {
        if (dialogCancelCallback) {
            dialogCancelCallback();
        }
        hideDialog();
    }

    // Alert dialog (replaces native alert)
    function showAlert(message, title = 'Notice') {
        showDialog(title, 'alertDialogTemplate', 'OK', null, { alertMode: true });
        setTimeout(() => {
            const msgEl = document.getElementById('alertMessage');
            if (msgEl) msgEl.textContent = message;
        }, 10);
    }

    // Confirm dialog (replaces native confirm)
    function showConfirm(message, title, onConfirm, options = {}) {
        const confirmText = options.confirmText || 'Confirm';
        const confirmClass = options.danger ? 'btn btn-primary btn-danger' : 'btn btn-primary';

        showDialog(title, 'confirmDialogTemplate', confirmText, onConfirm, {
            confirmClass,
            onCancel: options.onCancel
        });

        setTimeout(() => {
            const msgEl = document.getElementById('confirmMessage');
            if (msgEl) msgEl.textContent = message;
        }, 10);
    }

    // Prompt dialog (replaces native prompt)
    function showPrompt(label, title, defaultValue, onConfirm, options = {}) {
        const confirmText = options.confirmText || 'OK';

        let inputValue = defaultValue || '';

        showDialog(title, 'promptDialogTemplate', confirmText, () => {
            const input = document.getElementById('dialogPromptInput');
            if (input && onConfirm) {
                onConfirm(input.value.trim());
            }
        });

        setTimeout(() => {
            const labelEl = document.getElementById('dialogPromptLabel');
            const inputEl = document.getElementById('dialogPromptInput');
            if (labelEl) labelEl.textContent = label;
            if (inputEl) {
                inputEl.value = defaultValue || '';
                inputEl.focus();
                inputEl.select();
            }
        }, 10);
    }

    // ============================================
    // Add Directory Dialog
    // ============================================
    function showAddDirDialog() {
        showDialog('Add Directory', 'addDirDialogTemplate', 'Add', handleAddDir);

        // Setup path input to auto-fill name
        setTimeout(() => {
            const pathInput = document.getElementById('dirPathInput');
            const nameInput = document.getElementById('dirNameInput');

            if (pathInput && nameInput) {
                pathInput.addEventListener('input', () => {
                    const path = pathInput.value.trim();
                    if (path && !nameInput.dataset.userEdited) {
                        // Extract last part of path as name
                        const parts = path.replace(/\/+$/, '').split('/');
                        nameInput.value = parts[parts.length - 1] || '';
                    }
                });

                nameInput.addEventListener('input', () => {
                    nameInput.dataset.userEdited = 'true';
                });

                pathInput.focus();
            }
        }, 50);
    }

    async function handleAddDir() {
        const pathInput = document.getElementById('dirPathInput');
        const nameInput = document.getElementById('dirNameInput');

        const path = pathInput ? pathInput.value.trim() : '';
        const name = nameInput ? nameInput.value.trim() : '';

        if (!path) {
            showAlert('Please enter a directory path', 'Missing Path');
            return;
        }

        try {
            const data = await apiPost(`/api/workspaces/${state.activeWorkspaceId}/repos`, { path, name });
            if (data.status === 'ok') {
                await loadWorkspaces();
            } else {
                showAlert(data.message || 'Failed to add directory', 'Error');
            }
        } catch (err) {
            console.error('Failed to add directory:', err);
            showAlert('Failed to add directory', 'Error');
        }
    }

    // ============================================
    // Workspace Management
    // ============================================
    async function loadWorkspaces() {
        try {
            const data = await apiGet('/api/workspaces');
            if (data.status === 'ok') {
                state.workspaces = data.workspaces;
                state.activeWorkspaceId = data.active_workspace;
                renderWorkspaceSelector();
            }
        } catch (err) {
            console.error('Failed to load workspaces:', err);
        }
        // Load file tree for the active workspace
        await loadFileTree();
        renderRepoList();
    }

    function renderWorkspaceSelector() {
        if (!elements.workspaceSelect) return;

        let html = '';
        state.workspaces.forEach(ws => {
            const selected = ws.id === state.activeWorkspaceId ? 'selected' : '';
            html += `<option value="${ws.id}" ${selected}>${ws.name}</option>`;
        });
        elements.workspaceSelect.innerHTML = html;

        // Update workspace title in sidebar
        updateWorkspaceTitle();
    }

    function updateWorkspaceTitle() {
        const ws = getActiveWorkspace();
        if (elements.workspaceTitle && ws) {
            elements.workspaceTitle.textContent = ws.name;
        }
    }

    function createWorkspace() {
        showPrompt('Workspace Name', 'New Workspace', '', async (name) => {
            try {
                const data = await apiPost('/api/workspaces', { name });
                if (data.status === 'ok') {
                    await loadWorkspaces();
                }
            } catch (err) {
                console.error('Failed to create workspace:', err);
            }
        }, { confirmText: 'Create' });
    }

    function deleteWorkspace() {
        const ws = state.workspaces.find(w => w.id === state.activeWorkspaceId);
        if (!ws) return;

        showConfirm(
            `Are you sure you want to delete the workspace "${ws.name}"? This action cannot be undone.`,
            'Delete Workspace',
            async () => {
                try {
                    await apiDelete(`/api/workspaces/${state.activeWorkspaceId}`);
                    state.selectedFiles.clear();
                    await loadWorkspaces();
                } catch (err) {
                    console.error('Failed to delete workspace:', err);
                }
            },
            { confirmText: 'Delete', danger: true }
        );
    }

    function renameWorkspace() {
        const ws = state.workspaces.find(w => w.id === state.activeWorkspaceId);
        if (!ws) return;

        showPrompt('Workspace Name', 'Rename Workspace', ws.name, async (newName) => {
            if (!newName || newName === ws.name) return;

            try {
                await apiPost(`/api/workspaces/${state.activeWorkspaceId}/rename`, { name: newName });
                await loadWorkspaces();
            } catch (err) {
                console.error('Failed to rename workspace:', err);
            }
        }, { confirmText: 'Rename' });
    }

    async function switchWorkspace(workspaceId) {
        if (workspaceId === state.activeWorkspaceId) return;

        try {
            await apiPost(`/api/workspaces/${workspaceId}/activate`);
            state.activeWorkspaceId = workspaceId;
            // Clear selected files when switching workspaces
            state.selectedFiles.clear();
            // Load the file tree for the new workspace
            await loadFileTree();
            renderRepoList();
            renderSelectedFiles();
            updateTotalTokens();
        } catch (err) {
            console.error('Failed to switch workspace:', err);
        }
    }

    // ============================================
    // Repository Management
    // ============================================
    function getActiveWorkspace() {
        return state.workspaces.find(w => w.id === state.activeWorkspaceId);
    }

    // Show loading state in repo list
    function showRepoListLoading() {
        if (!elements.repoList) return;
        elements.repoList.innerHTML = `
            <div class="loading-state">
                <div class="loading-spinner"></div>
                <p class="loading-text">Loading directories...</p>
            </div>
        `;
    }

    // Load file tree from API
    async function loadFileTree() {
        if (!state.activeWorkspaceId) {
            state.fileTree = {};
            return;
        }

        // Show loading indicator
        showRepoListLoading();

        try {
            const data = await apiGet(`/api/workspaces/${state.activeWorkspaceId}/files`);
            if (data.status === 'ok') {
                state.fileTree = data.tree || {};
            } else {
                console.error('Failed to load file tree:', data.message);
                state.fileTree = {};
            }
        } catch (err) {
            console.error('Failed to load file tree:', err);
            state.fileTree = {};
        }
    }

    function getAllFilesInNode(node) {
        const files = [];
        if (node.type === 'file') {
            files.push(node.path);
        } else if (node.children) {
            node.children.forEach(child => {
                files.push(...getAllFilesInNode(child));
            });
        }
        return files;
    }

    // Fetch file content from API
    async function fetchFileContent(path) {
        try {
            const data = await apiGet(`/api/file?path=${encodeURIComponent(path)}`);
            if (data.status === 'ok') {
                return data.content;
            }
            return `// Error loading file: ${data.message || 'Unknown error'}\n// Path: ${path}`;
        } catch (err) {
            console.error('Failed to fetch file content:', err);
            return `// Error loading file: ${err.message}\n// Path: ${path}`;
        }
    }

    async function showFilePreview(path, name) {
        showDialog(name, 'filePreviewTemplate', 'Close', () => {
            hideDialog();
        }, { showCancel: false });

        // Show loading state
        setTimeout(async () => {
            const pathEl = document.getElementById('filePreviewPath');
            const contentEl = document.getElementById('filePreviewContent');
            if (pathEl) pathEl.textContent = path;
            if (contentEl) {
                contentEl.textContent = 'Loading...';
                const content = await fetchFileContent(path);
                contentEl.textContent = content;
            }
        }, 10);
    }

    function isNodeFullySelected(node) {
        if (node.type === 'file') {
            return state.selectedFiles.has(node.path);
        }
        // For directories, check if all files within are selected
        const allFiles = getAllFilesInNode(node);
        // Empty directory (no files) - not fully selected (nothing to select)
        if (allFiles.length === 0) return false;
        // Check if all files are selected
        return allFiles.every(f => state.selectedFiles.has(f));
    }

    function isNodePartiallySelected(node) {
        if (node.type === 'file') return false;
        if (!node.children || node.children.length === 0) return false;
        const allFiles = getAllFilesInNode(node);
        const selectedCount = allFiles.filter(f => state.selectedFiles.has(f)).length;
        return selectedCount > 0 && selectedCount < allFiles.length;
    }

    function toggleNodeSelection(node) {
        const allFiles = getAllFilesInNode(node);
        const allSelected = isNodeFullySelected(node);

        if (allSelected) {
            allFiles.forEach(f => state.selectedFiles.delete(f));
        } else {
            allFiles.forEach(f => state.selectedFiles.add(f));
        }

        renderRepoList();
        renderSelectedFiles();
        updateTotalTokens();
    }

    // Set node selection based on explicit select/deselect action
    function setNodeSelection(node, shouldSelect) {
        const allFiles = getAllFilesInNode(node);

        if (shouldSelect) {
            allFiles.forEach(f => state.selectedFiles.add(f));
        } else {
            // Remove files from tree
            allFiles.forEach(f => state.selectedFiles.delete(f));

            // Also remove any files that are under this path but not in the visible tree
            // This handles the case where tree depth is limited or tree not expanded
            const nodePath = node.path;
            const filesToRemove = [];
            state.selectedFiles.forEach(f => {
                if (f === nodePath || f.startsWith(nodePath + '/')) {
                    filesToRemove.push(f);
                }
            });
            filesToRemove.forEach(f => state.selectedFiles.delete(f));
        }
        renderRepoList();
        renderSelectedFiles();
        updateTotalTokens();
    }

    function toggleFolderExpand(path) {
        if (state.expandedFolders.has(path)) {
            state.expandedFolders.delete(path);
        } else {
            state.expandedFolders.add(path);
        }
        renderRepoList();
    }

    function renderTreeNode(node, depth = 0, forceExpand = false) {
        const indent = depth * 16;
        const isExpanded = forceExpand || state.expandedFolders.has(node.path);
        const isSelected = isNodeFullySelected(node);
        const isPartial = isNodePartiallySelected(node);

        let html = '';

        if (node.type === 'dir') {
            const expandIcon = isExpanded ? 'v' : '>';
            const checkboxClass = isPartial ? 'partial' : (isSelected ? 'checked' : '');

            html += `
                <div class="tree-item tree-dir" data-path="${node.path}" style="padding-left: ${indent}px;">
                    <span class="tree-expand" data-path="${node.path}">${expandIcon}</span>
                    <label class="tree-checkbox ${checkboxClass}">
                        <input type="checkbox" ${isSelected ? 'checked' : ''} data-path="${node.path}" data-type="dir" />
                        <span class="checkbox-visual"></span>
                    </label>
                    <span class="tree-name tree-dir-name tree-toggle" data-path="${node.path}">${node.name}</span>
                </div>
            `;

            if (isExpanded && node.children) {
                node.children.forEach(child => {
                    html += renderTreeNode(child, depth + 1, forceExpand);
                });
            }
        } else {
            html += `
                <div class="tree-item tree-file" data-path="${node.path}" style="padding-left: ${indent}px;">
                    <span class="tree-expand-placeholder"></span>
                    <label class="tree-checkbox ${isSelected ? 'checked' : ''}">
                        <input type="checkbox" ${isSelected ? 'checked' : ''} data-path="${node.path}" data-type="file" />
                        <span class="checkbox-visual"></span>
                    </label>
                    <span class="tree-name tree-file-name file-preview" data-path="${node.path}" data-name="${node.name}">${node.name}</span>
                </div>
            `;
        }

        return html;
    }

    function renderRepoTree(repoId, repoData, forceExpand = false) {
        const isExpanded = forceExpand || state.expandedFolders.has(repoData.path);
        // Create a proper node to check selection status
        const repoNode = { type: 'dir', children: repoData.children || [], path: repoData.path };
        const isSelected = isNodeFullySelected(repoNode);
        const isPartial = isNodePartiallySelected(repoNode);
        const expandIcon = isExpanded ? 'v' : '>';
        const checkboxClass = isPartial ? 'partial' : (isSelected ? 'checked' : '');

        let html = `
            <div class="repo-tree" data-repo-id="${repoId}">
                <div class="tree-item tree-repo" data-path="${repoData.path}" title="${repoData.path}">
                    <span class="tree-expand" data-path="${repoData.path}">${expandIcon}</span>
                    <label class="tree-checkbox ${checkboxClass}">
                        <input type="checkbox" ${isSelected ? 'checked' : ''} data-path="${repoData.path}" data-type="repo" data-repo-id="${repoId}" />
                        <span class="checkbox-visual"></span>
                    </label>
                    <span class="tree-name tree-repo-name tree-toggle" data-path="${repoData.path}">${repoData.name}</span>
                    <button class="btn-delete-dir" data-repo-id="${repoId}" title="Remove directory">🗑</button>
                </div>
        `;

        if (isExpanded && repoData.children) {
            html += '<div class="tree-children">';
            repoData.children.forEach(child => {
                html += renderTreeNode(child, 1, forceExpand);
            });
            html += '</div>';
        }

        html += '</div>';
        return html;
    }

    function renderRepoList() {
        if (!elements.repoList) {
            return;
        }

        const ws = getActiveWorkspace();
        updateWorkspaceTitle();

        const query = state.searchQuery;

        // Render file tree from state, applying search filter
        let html = '';
        Object.keys(state.fileTree).forEach(repoId => {
            const repoData = state.fileTree[repoId];

            // Apply search filter if there's a query
            if (query) {
                const filteredData = filterTreeBySearch(repoData, query);
                if (filteredData) {
                    // Auto-expand when searching
                    html += renderRepoTree(repoId, filteredData, true);
                }
            } else {
                html += renderRepoTree(repoId, repoData, false);
            }
        });

        if (!html) {
            const emptyMessage = query
                ? `<p class="empty-text">No files match "${query}"</p>`
                : '<p class="empty-text">No directories added</p>';
            const emptyHint = query
                ? '<p class="empty-hint">Try a different search term</p>'
                : '<p class="empty-hint">Click "Add Directory" to get started</p>';

            elements.repoList.innerHTML = `
                <div class="empty-state">
                    ${emptyMessage}
                    ${emptyHint}
                </div>
            `;
            return;
        }

        elements.repoList.innerHTML = html;

        // Add event listeners for expand/collapse (icon)
        const expandIcons = elements.repoList.querySelectorAll('.tree-expand');
        expandIcons.forEach(el => {
            el.addEventListener('click', (e) => {
                e.stopPropagation();
                toggleFolderExpand(el.dataset.path);
            });
        });

        // Add event listeners for expand/collapse (name click)
        const toggleNames = elements.repoList.querySelectorAll('.tree-toggle');
        toggleNames.forEach(el => {
            el.addEventListener('click', (e) => {
                e.stopPropagation();
                toggleFolderExpand(el.dataset.path);
            });
        });

        // Add event listeners for checkboxes
        elements.repoList.querySelectorAll('.tree-checkbox input').forEach(checkbox => {
            checkbox.addEventListener('change', (e) => {
                e.stopPropagation();
                const path = checkbox.dataset.path;
                const type = checkbox.dataset.type;
                const shouldSelect = checkbox.checked; // Use the checkbox state to determine action

                if (type === 'file') {
                    if (shouldSelect) {
                        state.selectedFiles.add(path);
                    } else {
                        state.selectedFiles.delete(path);
                    }
                    renderRepoList();
                    renderSelectedFiles();
                    updateTotalTokens();
                } else {
                    // Find the node and toggle all files within
                    let node = null;
                    if (type === 'repo') {
                        node = state.fileTree[checkbox.dataset.repoId];
                        if (node) {
                            node = { type: 'dir', children: node.children, path: node.path };
                        }
                    } else {
                        node = findNodeByPath(path);
                    }
                    if (node) {
                        // Use checkbox state to determine selection
                        setNodeSelection(node, shouldSelect);
                    }
                }
            });
        });

        // Add event listeners for file preview (click on file name)
        elements.repoList.querySelectorAll('.file-preview').forEach(el => {
            el.addEventListener('click', (e) => {
                e.stopPropagation();
                const path = el.dataset.path;
                const name = el.dataset.name;
                showFilePreview(path, name);
            });
        });

        // Add event listeners for delete directory buttons
        elements.repoList.querySelectorAll('.btn-delete-dir').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const repoId = btn.dataset.repoId;
                if (repoId) {
                    removeRepo(repoId);
                }
            });
        });
    }

    function findNodeByPath(targetPath, nodes = null) {
        if (!nodes) {
            for (const repoId in state.fileTree) {
                const repo = state.fileTree[repoId];
                if (repo.path === targetPath) {
                    return { type: 'dir', children: repo.children, path: repo.path };
                }
                const found = findNodeByPath(targetPath, repo.children);
                if (found) return found;
            }
            return null;
        }

        for (const node of nodes) {
            if (node.path === targetPath) return node;
            if (node.children) {
                const found = findNodeByPath(targetPath, node.children);
                if (found) return found;
            }
        }
        return null;
    }

    function removeRepo(repoId) {
        showConfirm(
            'Are you sure you want to remove this directory from the workspace?',
            'Remove Directory',
            async () => {
                try {
                    await apiDelete(`/api/workspaces/${state.activeWorkspaceId}/repos/${repoId}`);
                    await loadWorkspaces();
                } catch (err) {
                    console.error('Failed to remove directory:', err);
                }
            },
            { confirmText: 'Remove', danger: true }
        );
    }

    async function activateRepo(repoId) {
        try {
            await apiPost(`/api/workspaces/${state.activeWorkspaceId}/repos/${repoId}/activate`);
            const ws = getActiveWorkspace();
            if (ws) ws.active_repo = repoId;
            renderRepoList();
            // TODO: Load files for this repo
        } catch (err) {
            console.error('Failed to activate repository:', err);
        }
    }

    // ============================================
    // Theme Management
    // ============================================
    function initTheme() {
        document.documentElement.setAttribute('data-theme', state.theme);
        updateThemeIcon();
    }

    function toggleTheme() {
        state.theme = state.theme === 'light' ? 'dark' : 'light';
        document.documentElement.setAttribute('data-theme', state.theme);
        localStorage.setItem('heroprompt-theme', state.theme);
        updateThemeIcon();
    }

    function updateThemeIcon() {
        if (elements.themeToggle) {
            elements.themeToggle.textContent = state.theme === 'light' ? 'Dark' : 'Light';
        }
    }

    // ============================================
    // Token Estimation
    // ============================================
    function estimateTokens(text) {
        // Rough estimation: ~4 characters per token for English text
        // This is a simplified estimation; actual tokenization varies by model
        if (!text) return 0;
        return Math.ceil(text.length / 4);
    }

    function formatTokens(count) {
        if (count >= 1000000) {
            return (count / 1000000).toFixed(1) + 'M';
        } else if (count >= 1000) {
            return (count / 1000).toFixed(1) + 'K';
        }
        return count.toString();
    }

    function formatSize(bytes) {
        if (bytes >= 1024 * 1024) {
            return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
        } else if (bytes >= 1024) {
            return (bytes / 1024).toFixed(1) + ' KB';
        }
        return bytes + ' B';
    }

    // ============================================
    // Prompt Input Handling
    // ============================================
    function updatePromptTokens() {
        const text = elements.promptInput ? elements.promptInput.value : '';
        const tokens = estimateTokens(text);
        if (elements.promptTokens) {
            elements.promptTokens.textContent = formatTokens(tokens) + ' tokens';
        }
        updateTotalTokens();
        updateGenerateButtonState();
    }

    function clearPrompt() {
        if (elements.promptInput) {
            elements.promptInput.value = '';
            updatePromptTokens();
        }
    }

    function updateGenerateButtonState() {
        const hasPrompt = elements.promptInput && elements.promptInput.value.trim().length > 0;
        const hasFiles = state.selectedFiles.size > 0;
        const canGenerate = hasPrompt || hasFiles;

        if (elements.generateBtn) {
            elements.generateBtn.disabled = !canGenerate;
        }
        if (elements.copyAllBtn) {
            elements.copyAllBtn.disabled = !canGenerate;
        }
    }

    // ============================================
    // File Search
    // ============================================
    function handleWorkspaceSearch() {
        const query = elements.workspaceSearch ? elements.workspaceSearch.value.toLowerCase().trim() : '';
        state.searchQuery = query;
        renderRepoList();
    }

    function clearSearch() {
        if (elements.workspaceSearch) {
            elements.workspaceSearch.value = '';
            state.searchQuery = '';
            renderRepoList();
        }
    }

    // Check if a node or its children match the search query
    function nodeMatchesSearch(node, query) {
        if (!query) return true;

        // Check if this node's name matches
        if (node.name && node.name.toLowerCase().includes(query)) {
            return true;
        }

        // For directories, check if any children match
        if (node.type === 'dir' && node.children) {
            return node.children.some(child => nodeMatchesSearch(child, query));
        }

        return false;
    }

    // Filter tree nodes based on search query
    function filterTreeBySearch(node, query) {
        if (!query) return node;

        // For files, return the node if it matches
        if (node.type === 'file') {
            if (node.name && node.name.toLowerCase().includes(query)) {
                return node;
            }
            return null;
        }

        // For directories, filter children recursively
        if (node.type === 'dir' && node.children) {
            const filteredChildren = node.children
                .map(child => filterTreeBySearch(child, query))
                .filter(child => child !== null);

            // Include directory if it has matching children or its name matches
            if (filteredChildren.length > 0 || (node.name && node.name.toLowerCase().includes(query))) {
                return { ...node, children: filteredChildren };
            }
        }

        return null;
    }

    // ============================================
    // Selection Management
    // ============================================
    function updateSelectionStats() {
        const count = state.selectedFiles.size;
        if (elements.selectedCount) {
            elements.selectedCount.textContent = count + ' selected';
        }
        updateTotalTokens();
        renderSelectedFiles();
        updateGenerateButtonState();
    }

    function updateTotalTokens() {
        const promptTokens = estimateTokens(elements.promptInput ? elements.promptInput.value : '');

        // Calculate tokens from selected files
        let fileTokens = 0;
        state.selectedFiles.forEach(filePath => {
            const fileInfo = getFileInfo(filePath);
            if (fileInfo && fileInfo.size) {
                fileTokens += Math.ceil(fileInfo.size / 4);
            }
        });

        const totalTokens = promptTokens + fileTokens;
        if (elements.totalTokens) {
            elements.totalTokens.textContent = formatTokens(totalTokens);
        }
    }

    function getFileInfo(filePath) {
        // Look up file info from state file tree
        for (const repoId in state.fileTree) {
            const result = findFileInTree(filePath, state.fileTree[repoId].children);
            if (result) return result;
        }
        return { name: filePath.split('/').pop(), size: 0 };
    }

    function findFileInTree(targetPath, nodes) {
        if (!nodes) return null;
        for (const node of nodes) {
            if (node.path === targetPath) return node;
            if (node.children) {
                const found = findFileInTree(targetPath, node.children);
                if (found) return found;
            }
        }
        return null;
    }

    function deselectAllFiles() {
        state.selectedFiles.clear();
        updateSelectionStats();
    }

    // ============================================
    // Render Selected Files
    // ============================================
    function renderSelectedFiles() {
        if (!elements.selectedFiles) return;

        // Update the count in header
        if (elements.selectedFilesCount) {
            elements.selectedFilesCount.textContent = `(${state.selectedFiles.size})`;
        }

        if (state.selectedFiles.size === 0) {
            elements.selectedFiles.innerHTML = `
                <div class="empty-state">
                    <p class="empty-text">No files selected</p>
                    <p class="empty-hint">Check files in the explorer to add them</p>
                </div>
            `;
            if (elements.selectionTokens) elements.selectionTokens.textContent = '0 tokens';
            if (elements.selectionSize) elements.selectionSize.textContent = '0 KB';
            return;
        }

        // Build file list with info for sorting
        const filesWithInfo = Array.from(state.selectedFiles).map(filePath => {
            const fileInfo = getFileInfo(filePath);
            return {
                path: filePath,
                name: fileInfo.name || filePath.split('/').pop(),
                size: fileInfo.size || 0,
                tokens: Math.ceil((fileInfo.size || 0) / 4)
            };
        });

        // Sort based on current sort setting
        filesWithInfo.sort((a, b) => {
            switch (state.sortBy) {
                case 'name':
                    return a.name.localeCompare(b.name);
                case 'path':
                    return a.path.localeCompare(b.path);
                case 'size':
                    return b.size - a.size; // Descending
                default:
                    return a.name.localeCompare(b.name);
            }
        });

        let html = '';
        let totalSize = 0;

        filesWithInfo.forEach(file => {
            totalSize += file.size;
            html += `
                <div class="selected-file-item" data-path="${file.path}">
                    <div class="selected-file-info">
                        <div class="selected-file-name">${file.name}</div>
                        <div class="selected-file-path">${file.path}</div>
                    </div>
                    <span class="selected-file-tokens">${formatTokens(file.tokens)}</span>
                    <button class="btn btn-sm btn-ghost selected-file-remove" data-path="${file.path}">Remove</button>
                </div>
            `;
        });
        elements.selectedFiles.innerHTML = html;

        // Update stats
        const totalTokens = Math.ceil(totalSize / 4);
        if (elements.selectionTokens) elements.selectionTokens.textContent = formatTokens(totalTokens) + ' tokens';
        if (elements.selectionSize) elements.selectionSize.textContent = formatSize(totalSize);

        // Add remove handlers
        elements.selectedFiles.querySelectorAll('.selected-file-remove').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const path = btn.dataset.path;
                state.selectedFiles.delete(path);
                renderRepoList();
                renderSelectedFiles();
                updateTotalTokens();
            });
        });
    }

    function handleSortChange() {
        if (elements.sortSelect) {
            state.sortBy = elements.sortSelect.value;
            renderSelectedFiles();
        }
    }

    // ============================================
    // File Tree Rendering (Demo/Placeholder)
    // ============================================
    function renderFileTree() {
        if (!elements.fileTree) return;

        // Show empty state when no repo is loaded
        if (!state.repoPath) {
            elements.fileTree.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">📂</div>
                    <p class="empty-text">No repository loaded</p>
                    <p class="empty-hint">Enter a path above or drag a folder here</p>
                </div>
            `;
            return;
        }

        // TODO: Render actual file tree from backend
    }

    function collapseAllFolders() {
        state.expandedFolders.clear();
        renderFileTree();
    }

    function expandAllFolders() {
        // TODO: Expand all folders when backend provides folder list
    }

    // ============================================
    // Modal Management
    // ============================================
    function showModal() {
        if (elements.outputModal) {
            elements.outputModal.style.display = 'flex';
        }
    }

    function hideModal() {
        if (elements.outputModal) {
            elements.outputModal.style.display = 'none';
        }
    }

    // ============================================
    // Generate Context
    // ============================================

    // Build file map tree from selected files
    function buildFileMapTree() {
        if (state.selectedFiles.size === 0) return '';

        const sortedFiles = Array.from(state.selectedFiles).sort();

        // Find common base path
        let commonBase = '';
        if (sortedFiles.length > 0) {
            const parts = sortedFiles[0].split('/');
            for (let i = 0; i < parts.length - 1; i++) {
                const prefix = parts.slice(0, i + 1).join('/');
                if (sortedFiles.every(f => f.startsWith(prefix + '/'))) {
                    commonBase = prefix;
                }
            }
        }

        // Build tree structure
        let tree = commonBase ? commonBase.split('/').pop() + '/\n' : '';
        const baseLen = commonBase.length > 0 ? commonBase.length + 1 : 0;

        // Group files by directory
        const filesByDir = new Map();
        sortedFiles.forEach(filePath => {
            const relPath = filePath.slice(baseLen);
            const dir = relPath.includes('/') ? relPath.substring(0, relPath.lastIndexOf('/')) : '';
            if (!filesByDir.has(dir)) {
                filesByDir.set(dir, []);
            }
            filesByDir.get(dir).push(relPath.split('/').pop());
        });

        // Render tree with indentation
        const dirs = Array.from(filesByDir.keys()).sort();
        dirs.forEach(dir => {
            if (dir) {
                const depth = dir.split('/').length;
                const indent = '  '.repeat(depth);
                tree += `${indent}${dir.split('/').pop()}/\n`;
            }
            const files = filesByDir.get(dir);
            const depth = dir ? dir.split('/').length + 1 : 1;
            const indent = '  '.repeat(depth);
            files.forEach(file => {
                tree += `${indent}${file} *\n`;
            });
        });

        return tree;
    }

    async function generateContext() {
        const prompt = elements.promptInput ? elements.promptInput.value : '';

        // Show modal with loading state
        showModal();
        if (elements.outputPreview) {
            elements.outputPreview.textContent = 'Loading file contents...';
        }

        // Build user_instructions section
        let userInstructions = prompt || '';

        // Build file_map section
        const fileMap = buildFileMapTree();

        // Build file_contents section
        let fileContents = '';
        if (state.selectedFiles.size > 0) {
            for (const filePath of state.selectedFiles) {
                try {
                    const data = await apiGet(`/api/file?path=${encodeURIComponent(filePath)}`);
                    if (data.status === 'ok' && data.content) {
                        const ext = filePath.split('.').pop() || '';
                        fileContents += `${filePath}\n`;
                        fileContents += '```' + ext + '\n';
                        fileContents += data.content;
                        if (!data.content.endsWith('\n')) {
                            fileContents += '\n';
                        }
                        fileContents += '```\n\n';
                    } else {
                        fileContents += `${filePath}\n`;
                        fileContents += '```\n';
                        fileContents += `// Error loading file: ${data.message || 'Unknown error'}\n`;
                        fileContents += '```\n\n';
                    }
                } catch (err) {
                    fileContents += `${filePath}\n`;
                    fileContents += '```\n';
                    fileContents += `// Error loading file: ${err.message}\n`;
                    fileContents += '```\n\n';
                }
            }
        }

        // Build final output using template format
        let output = '';
        if (!userInstructions && !fileMap && !fileContents) {
            output = '// No prompt or files selected. Enter a prompt and/or select files to generate context.';
        } else {
            output += '<user_instructions>\n';
            output += userInstructions + '\n';
            output += '</user_instructions>\n\n';

            output += '<file_map>\n';
            output += fileMap;
            output += '</file_map>\n\n';

            output += '<file_contents>\n';
            output += fileContents;
            output += '</file_contents>\n';
        }

        // Update modal with content
        if (elements.outputPreview) {
            elements.outputPreview.textContent = output;
        }
        if (elements.outputTokens) {
            elements.outputTokens.textContent = formatTokens(estimateTokens(output)) + ' tokens';
        }
        if (elements.outputSize) {
            elements.outputSize.textContent = output.length + ' characters';
        }
    }

    // ============================================
    // Clipboard Operations
    // ============================================
    async function copyToClipboard(text) {
        try {
            await navigator.clipboard.writeText(text);
            return true;
        } catch (err) {
            console.error('Failed to copy:', err);
            return false;
        }
    }

    async function copyOutput() {
        const text = elements.outputPreview ? elements.outputPreview.textContent : '';
        const success = await copyToClipboard(text);
        if (success && elements.copyOutputBtn) {
            const originalText = elements.copyOutputBtn.innerHTML;
            elements.copyOutputBtn.innerHTML = '<span class="btn-icon-left">✓</span> Copied!';
            setTimeout(() => {
                elements.copyOutputBtn.innerHTML = originalText;
            }, 2000);
        }
    }

    async function copyAll() {
        // Generate and copy context
        generateContext();
        await copyOutput();
        hideModal();
    }

    // ============================================
    // Resize Handles
    // ============================================
    function initResizeHandles() {
        let isResizing = false;
        let currentHandle = null;
        let startX = 0;
        let startWidth = 0;
        let targetPanel = null;
        let resizeDirection = 1; // 1 for left-to-right, -1 for right-to-left

        function startResize(e, handle, panel, direction) {
            isResizing = true;
            currentHandle = handle;
            startX = e.clientX;
            targetPanel = panel;
            resizeDirection = direction;
            handle.classList.add('active');

            if (targetPanel) {
                startWidth = targetPanel.offsetWidth;
            }

            document.addEventListener('mousemove', doResize);
            document.addEventListener('mouseup', stopResize);
            e.preventDefault();
        }

        function doResize(e) {
            if (!isResizing || !targetPanel) return;

            const diff = (e.clientX - startX) * resizeDirection;
            const newWidth = Math.max(200, Math.min(600, startWidth + diff));
            targetPanel.style.width = newWidth + 'px';
            targetPanel.style.flex = 'none';
        }

        function stopResize() {
            isResizing = false;
            if (currentHandle) {
                currentHandle.classList.remove('active');
            }
            document.removeEventListener('mousemove', doResize);
            document.removeEventListener('mouseup', stopResize);
        }

        // Handle 0: Between workspace sidebar and prompt panel
        if (elements.resizeHandle0) {
            const workspaceSidebar = document.querySelector('.workspace-sidebar');
            elements.resizeHandle0.addEventListener('mousedown', (e) => startResize(e, elements.resizeHandle0, workspaceSidebar, 1));
        }

        // Handle 1: Between prompt panel and selected files panel
        if (elements.resizeHandle1) {
            const selectedPanel = document.querySelector('.selected-panel');
            elements.resizeHandle1.addEventListener('mousedown', (e) => startResize(e, elements.resizeHandle1, selectedPanel, -1));
        }
    }

    // ============================================
    // Event Listeners
    // ============================================
    function initEventListeners() {
        // Workspace controls
        if (elements.workspaceSelect) {
            elements.workspaceSelect.addEventListener('change', (e) => switchWorkspace(e.target.value));
        }
        if (elements.newWorkspaceBtn) {
            elements.newWorkspaceBtn.addEventListener('click', createWorkspace);
        }
        if (elements.renameWorkspaceBtn) {
            elements.renameWorkspaceBtn.addEventListener('click', renameWorkspace);
        }
        if (elements.deleteWorkspaceBtn) {
            elements.deleteWorkspaceBtn.addEventListener('click', deleteWorkspace);
        }

        // Add Directory button
        if (elements.addDirBtn) {
            elements.addDirBtn.addEventListener('click', showAddDirDialog);
        }

        // Dialog controls
        if (elements.dialogCancelBtn) {
            elements.dialogCancelBtn.addEventListener('click', cancelDialog);
        }
        if (elements.dialogConfirmBtn) {
            elements.dialogConfirmBtn.addEventListener('click', confirmDialog);
        }
        if (elements.dialogModal) {
            elements.dialogModal.querySelector('.modal-overlay')?.addEventListener('click', hideDialog);
        }

        // Theme toggle
        if (elements.themeToggle) {
            elements.themeToggle.addEventListener('click', toggleTheme);
        }

        // Workspace search
        if (elements.workspaceSearch) {
            elements.workspaceSearch.addEventListener('input', handleWorkspaceSearch);
        }
        if (elements.clearSearchBtn) {
            elements.clearSearchBtn.addEventListener('click', clearSearch);
        }

        // Prompt input
        if (elements.promptInput) {
            elements.promptInput.addEventListener('input', updatePromptTokens);
        }
        if (elements.clearPromptBtn) {
            elements.clearPromptBtn.addEventListener('click', clearPrompt);
        }

        // Selection controls
        if (elements.deselectAllBtn) {
            elements.deselectAllBtn.addEventListener('click', deselectAllFiles);
        }

        // Sort control
        if (elements.sortSelect) {
            elements.sortSelect.addEventListener('change', handleSortChange);
        }

        // Generate button
        if (elements.generateBtn) {
            elements.generateBtn.addEventListener('click', generateContext);
        }

        // Copy buttons
        if (elements.copyAllBtn) {
            elements.copyAllBtn.addEventListener('click', copyAll);
        }
        if (elements.copyOutputBtn) {
            elements.copyOutputBtn.addEventListener('click', copyOutput);
        }

        // Modal
        if (elements.closeModalBtn) {
            elements.closeModalBtn.addEventListener('click', hideModal);
        }
        if (elements.outputModal) {
            elements.outputModal.querySelector('.modal-overlay')?.addEventListener('click', hideModal);
        }

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            // Escape to close modal
            if (e.key === 'Escape') {
                hideModal();
            }
            // Cmd/Ctrl + Enter to generate
            if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
                generateContext();
            }
        });
    }

    // ============================================
    // Initialization
    // ============================================
    async function init() {
        initTheme();
        initEventListeners();
        initResizeHandles();

        // Load workspaces from server
        await loadWorkspaces();

        renderSelectedFiles();
        updatePromptTokens();
        updateGenerateButtonState();
    }

    // Run when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();

