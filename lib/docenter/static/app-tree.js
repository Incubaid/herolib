// Docenter Application with File Tree
(function () {
    'use strict';

    // State management
    let currentFile = null;
    let currentFilePath = null;
    let editor = null;
    let isScrollingSynced = true;
    let scrollTimeout = null;
    let isDarkMode = false;
    let fileTree = [];
    let contextMenuTarget = null;
    let clipboard = null; // For copy/move operations

    // Dark mode management
    function initDarkMode() {
        const savedMode = localStorage.getItem('darkMode');
        if (savedMode === 'true') {
            enableDarkMode();
        }
    }

    function enableDarkMode() {
        isDarkMode = true;
        document.body.classList.add('dark-mode');
        document.getElementById('darkModeIcon').innerHTML = '<i class="bi bi-sun-fill"></i>';
        localStorage.setItem('darkMode', 'true');

        mermaid.initialize({
            startOnLoad: false,
            theme: 'dark',
            securityLevel: 'loose'
        });

        if (editor && editor.getValue()) {
            updatePreview();
        }
    }

    function disableDarkMode() {
        isDarkMode = false;
        document.body.classList.remove('dark-mode');
        // document.getElementById('darkModeIcon').textContent = '🌙';
        localStorage.setItem('darkMode', 'false');

        mermaid.initialize({
            startOnLoad: false,
            theme: 'default',
            securityLevel: 'loose'
        });

        if (editor && editor.getValue()) {
            updatePreview();
        }
    }

    function toggleDarkMode() {
        if (isDarkMode) {
            disableDarkMode();
        } else {
            enableDarkMode();
        }
    }

    // Initialize Mermaid
    mermaid.initialize({
        startOnLoad: false,
        theme: 'default',
        securityLevel: 'loose'
    });

    // Configure marked.js for markdown parsing
    marked.setOptions({
        breaks: true,
        gfm: true,
        headerIds: true,
        mangle: false,
        sanitize: false,
        smartLists: true,
        smartypants: true,
        xhtml: false
    });

    // Handle image upload
    async function uploadImage(file) {
        const formData = new FormData();
        formData.append('file', file);

        try {
            const response = await fetch('/api/upload-image', {
                method: 'POST',
                body: formData
            });

            if (!response.ok) throw new Error('Upload failed');

            const result = await response.json();
            return result.url;
        } catch (error) {
            console.error('Error uploading image:', error);
            showNotification('Error uploading image', 'danger');
            return null;
        }
    }

    // Handle drag and drop for images
    function setupDragAndDrop() {
        const editorElement = document.querySelector('.CodeMirror');

        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            editorElement.addEventListener(eventName, preventDefaults, false);
        });

        function preventDefaults(e) {
            e.preventDefault();
            e.stopPropagation();
        }

        ['dragenter', 'dragover'].forEach(eventName => {
            editorElement.addEventListener(eventName, () => {
                editorElement.classList.add('drag-over');
            }, false);
        });

        ['dragleave', 'drop'].forEach(eventName => {
            editorElement.addEventListener(eventName, () => {
                editorElement.classList.remove('drag-over');
            }, false);
        });

        editorElement.addEventListener('drop', async (e) => {
            const files = e.dataTransfer.files;

            if (files.length === 0) return;

            const imageFiles = Array.from(files).filter(file =>
                file.type.startsWith('image/')
            );

            if (imageFiles.length === 0) {
                showNotification('Please drop image files only', 'warning');
                return;
            }

            showNotification(`Uploading ${imageFiles.length} image(s)...`, 'info');

            for (const file of imageFiles) {
                const url = await uploadImage(file);
                if (url) {
                    const cursor = editor.getCursor();
                    const imageMarkdown = `![${file.name}](${url})`;
                    editor.replaceRange(imageMarkdown, cursor);
                    editor.setCursor(cursor.line, cursor.ch + imageMarkdown.length);
                    showNotification(`Image uploaded: ${file.name}`, 'success');
                }
            }
        }, false);

        editorElement.addEventListener('paste', async (e) => {
            const items = e.clipboardData?.items;
            if (!items) return;

            for (const item of items) {
                if (item.type.startsWith('image/')) {
                    e.preventDefault();
                    const file = item.getAsFile();
                    if (file) {
                        showNotification('Uploading pasted image...', 'info');
                        const url = await uploadImage(file);
                        if (url) {
                            const cursor = editor.getCursor();
                            const imageMarkdown = `![pasted-image](${url})`;
                            editor.replaceRange(imageMarkdown, cursor);
                            showNotification('Image uploaded successfully', 'success');
                        }
                    }
                }
            }
        });
    }

    // Initialize CodeMirror editor
    function initEditor() {
        editor = CodeMirror.fromTextArea(document.getElementById('editor'), {
            mode: 'markdown',
            theme: 'monokai',
            lineNumbers: true,
            lineWrapping: true,
            autofocus: true,
            extraKeys: {
                'Ctrl-S': function () { saveFile(); },
                'Cmd-S': function () { saveFile(); }
            }
        });

        editor.on('change', debounce(updatePreview, 300));

        setTimeout(setupDragAndDrop, 100);

        setupScrollSync();
    }

    // Debounce function
    function debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    // Setup synchronized scrolling
    function setupScrollSync() {
        const previewDiv = document.getElementById('preview');

        editor.on('scroll', () => {
            if (!isScrollingSynced) return;

            const scrollInfo = editor.getScrollInfo();
            const scrollPercentage = scrollInfo.top / (scrollInfo.height - scrollInfo.clientHeight);

            const previewScrollHeight = previewDiv.scrollHeight - previewDiv.clientHeight;
            previewDiv.scrollTop = previewScrollHeight * scrollPercentage;
        });
    }

    // Update preview
    async function updatePreview() {
        const markdown = editor.getValue();
        const previewDiv = document.getElementById('preview');

        if (!markdown.trim()) {
            previewDiv.innerHTML = `
                <div class="text-muted text-center mt-5">
                    <h4>Preview</h4>
                    <p>Start typing in the editor to see the preview</p>
                </div>
            `;
            return;
        }

        try {
            let html = marked.parse(markdown);

            html = html.replace(
                /<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g,
                '<div class="mermaid">$1</div>'
            );

            previewDiv.innerHTML = html;

            const codeBlocks = previewDiv.querySelectorAll('pre code');
            codeBlocks.forEach(block => {
                const languageClass = Array.from(block.classList).find(cls => cls.startsWith('language-'));
                if (languageClass && languageClass !== 'language-mermaid') {
                    Prism.highlightElement(block);
                }
            });

            const mermaidElements = previewDiv.querySelectorAll('.mermaid');
            if (mermaidElements.length > 0) {
                try {
                    await mermaid.run({
                        nodes: mermaidElements,
                        suppressErrors: false
                    });
                } catch (error) {
                    console.error('Mermaid rendering error:', error);
                }
            }
        } catch (error) {
            console.error('Preview rendering error:', error);
            previewDiv.innerHTML = `
                <div class="alert alert-danger" role="alert">
                    <strong>Error rendering preview:</strong> ${error.message}
                </div>
            `;
        }
    }

    // ========================================================================
    // File Tree Management
    // ========================================================================

    async function loadFileTree() {
        try {
            const response = await fetch('/api/tree');
            if (!response.ok) throw new Error('Failed to load file tree');

            fileTree = await response.json();
            renderFileTree();
        } catch (error) {
            console.error('Error loading file tree:', error);
            showNotification('Error loading files', 'danger');
        }
    }

    function renderFileTree() {
        const container = document.getElementById('fileTree');
        container.innerHTML = '';

        if (fileTree.length === 0) {
            container.innerHTML = '<div class="text-muted text-center p-3">No files yet</div>';
            return;
        }

        fileTree.forEach(node => {
            container.appendChild(createTreeNode(node));
        });
    }

    function createTreeNode(node, level = 0) {
        const nodeDiv = document.createElement('div');
        nodeDiv.className = 'tree-node-wrapper';

        const nodeContent = document.createElement('div');
        nodeContent.className = 'tree-node';
        nodeContent.dataset.path = node.path;
        nodeContent.dataset.type = node.type;
        nodeContent.dataset.name = node.name;

        // Make draggable
        nodeContent.draggable = true;
        nodeContent.addEventListener('dragstart', handleDragStart);
        nodeContent.addEventListener('dragend', handleDragEnd);
        nodeContent.addEventListener('dragover', handleDragOver);
        nodeContent.addEventListener('dragleave', handleDragLeave);
        nodeContent.addEventListener('drop', handleDrop);

        const contentWrapper = document.createElement('div');
        contentWrapper.className = 'tree-node-content';

        if (node.type === 'directory') {
            const toggle = document.createElement('span');
            toggle.className = 'tree-node-toggle';
            toggle.addEventListener('click', (e) => {
                e.stopPropagation();
                toggleNode(nodeDiv);
            });
            contentWrapper.appendChild(toggle);
        } else {
            const spacer = document.createElement('span');
            spacer.style.width = '16px';
            contentWrapper.appendChild(spacer);
        }

        const icon = document.createElement('i');
        icon.className = node.type === 'directory' ? 'bi bi-folder tree-node-icon' : 'bi bi-file-earmark-text tree-node-icon';
        contentWrapper.appendChild(icon);

        const name = document.createElement('span');
        name.className = 'tree-node-name';
        name.textContent = node.name;
        contentWrapper.appendChild(name);

        if (node.type === 'file' && node.size) {
            const size = document.createElement('span');
            size.className = 'file-size-badge';
            size.textContent = formatFileSize(node.size);
            contentWrapper.appendChild(size);
        }

        nodeContent.appendChild(contentWrapper);

        nodeContent.addEventListener('click', (e) => {
            if (node.type === 'file') {
                loadFile(node.path);
            }
        });

        nodeContent.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            showContextMenu(e, node);
        });

        nodeDiv.appendChild(nodeContent);

        if (node.children && node.children.length > 0) {
            const childrenDiv = document.createElement('div');
            childrenDiv.className = 'tree-children collapsed';

            node.children.forEach(child => {
                childrenDiv.appendChild(createTreeNode(child, level + 1));
            });

            nodeDiv.appendChild(childrenDiv);
        }

        return nodeDiv;
    }

    function toggleNode(nodeWrapper) {
        const toggle = nodeWrapper.querySelector('.tree-node-toggle');
        const children = nodeWrapper.querySelector('.tree-children');

        if (children) {
            children.classList.toggle('collapsed');
            toggle.classList.toggle('expanded');
        }
    }

    function formatFileSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    }

    // ========================================================================
    // Drag and Drop for Files
    // ========================================================================

    let draggedNode = null;

    function handleDragStart(e) {
        draggedNode = {
            path: e.currentTarget.dataset.path,
            type: e.currentTarget.dataset.type,
            name: e.currentTarget.dataset.name
        };
        e.currentTarget.classList.add('dragging');
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', draggedNode.path);
    }

    function handleDragEnd(e) {
        e.currentTarget.classList.remove('dragging');
        document.querySelectorAll('.drag-over').forEach(el => {
            el.classList.remove('drag-over');
        });
    }

    function handleDragOver(e) {
        if (!draggedNode) return;

        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';

        const targetType = e.currentTarget.dataset.type;
        if (targetType === 'directory') {
            e.currentTarget.classList.add('drag-over');
        }
    }

    function handleDragLeave(e) {
        e.currentTarget.classList.remove('drag-over');
    }

    async function handleDrop(e) {
        e.preventDefault();
        e.currentTarget.classList.remove('drag-over');

        if (!draggedNode) return;

        const targetPath = e.currentTarget.dataset.path;
        const targetType = e.currentTarget.dataset.type;

        if (targetType !== 'directory') return;
        if (draggedNode.path === targetPath) return;

        const sourcePath = draggedNode.path;
        const destPath = targetPath + '/' + draggedNode.name;

        try {
            const response = await fetch('/api/file/move', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    source: sourcePath,
                    destination: destPath
                })
            });

            if (!response.ok) throw new Error('Move failed');

            showNotification(`Moved ${draggedNode.name}`, 'success');
            loadFileTree();
        } catch (error) {
            console.error('Error moving file:', error);
            showNotification('Error moving file', 'danger');
        }

        draggedNode = null;
    }

    // ========================================================================
    // Context Menu
    // ========================================================================

    function showContextMenu(e, node) {
        contextMenuTarget = node;
        const menu = document.getElementById('contextMenu');
        const pasteItem = document.getElementById('pasteMenuItem');

        // Show paste option only if clipboard has something and target is a directory
        if (clipboard && node.type === 'directory') {
            pasteItem.style.display = 'flex';
        } else {
            pasteItem.style.display = 'none';
        }

        menu.style.display = 'block';
        menu.style.left = e.pageX + 'px';
        menu.style.top = e.pageY + 'px';

        document.addEventListener('click', hideContextMenu);
    }

    function hideContextMenu() {
        const menu = document.getElementById('contextMenu');
        menu.style.display = 'none';
        document.removeEventListener('click', hideContextMenu);
    }

    // ========================================================================
    // File Operations
    // ========================================================================

    async function loadFile(path) {
        try {
            const response = await fetch(`/api/file?path=${encodeURIComponent(path)}`);
            if (!response.ok) throw new Error('Failed to load file');

            const data = await response.json();
            currentFile = data.filename;
            currentFilePath = path;

            document.getElementById('filenameInput').value = path;
            editor.setValue(data.content);
            updatePreview();

            document.querySelectorAll('.tree-node').forEach(node => {
                node.classList.remove('active');
            });
            document.querySelector(`[data-path="${path}"]`)?.classList.add('active');

            showNotification(`Loaded ${data.filename}`, 'info');
        } catch (error) {
            console.error('Error loading file:', error);
            showNotification('Error loading file', 'danger');
        }
    }

    async function saveFile() {
        const path = document.getElementById('filenameInput').value.trim();

        if (!path) {
            showNotification('Please enter a filename', 'warning');
            return;
        }

        const content = editor.getValue();

        try {
            const response = await fetch('/api/file', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path, content })
            });

            if (!response.ok) throw new Error('Failed to save file');

            const result = await response.json();
            currentFile = path.split('/').pop();
            currentFilePath = result.path;

            showNotification(`Saved ${currentFile}`, 'success');
            loadFileTree();
        } catch (error) {
            console.error('Error saving file:', error);
            showNotification('Error saving file', 'danger');
        }
    }

    async function deleteFile() {
        if (!currentFilePath) {
            showNotification('No file selected', 'warning');
            return;
        }

        if (!confirm(`Are you sure you want to delete ${currentFile}?`)) {
            return;
        }

        try {
            const response = await fetch(`/api/file?path=${encodeURIComponent(currentFilePath)}`, {
                method: 'DELETE'
            });

            if (!response.ok) throw new Error('Failed to delete file');

            showNotification(`Deleted ${currentFile}`, 'success');

            currentFile = null;
            currentFilePath = null;
            document.getElementById('filenameInput').value = '';
            editor.setValue('');
            updatePreview();

            loadFileTree();
        } catch (error) {
            console.error('Error deleting file:', error);
            showNotification('Error deleting file', 'danger');
        }
    }

    function newFile() {
        // Clear editor for new file
        currentFile = null;
        currentFilePath = null;
        document.getElementById('filenameInput').value = '';
        document.getElementById('filenameInput').focus();
        editor.setValue('');
        updatePreview();

        document.querySelectorAll('.tree-node').forEach(node => {
            node.classList.remove('active');
        });

        showNotification('Enter filename and start typing', 'info');
    }

    async function createFolder() {
        const folderName = prompt('Enter folder name:');
        if (!folderName) return;

        try {
            const response = await fetch('/api/directory', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path: folderName })
            });

            if (!response.ok) throw new Error('Failed to create folder');

            showNotification(`Created folder ${folderName}`, 'success');
            loadFileTree();
        } catch (error) {
            console.error('Error creating folder:', error);
            showNotification('Error creating folder', 'danger');
        }
    }

    // ========================================================================
    // Context Menu Actions
    // ========================================================================

    async function handleContextMenuAction(action) {
        if (!contextMenuTarget) return;

        switch (action) {
            case 'open':
                if (contextMenuTarget.type === 'file') {
                    loadFile(contextMenuTarget.path);
                }
                break;

            case 'rename':
                await renameItem();
                break;

            case 'copy':
                clipboard = { ...contextMenuTarget, operation: 'copy' };
                showNotification(`Copied ${contextMenuTarget.name}`, 'info');
                break;

            case 'move':
                clipboard = { ...contextMenuTarget, operation: 'move' };
                showNotification(`Cut ${contextMenuTarget.name}`, 'info');
                break;

            case 'paste':
                await pasteItem();
                break;

            case 'delete':
                await deleteItem();
                break;
        }
    }

    async function renameItem() {
        const newName = prompt(`Rename ${contextMenuTarget.name}:`, contextMenuTarget.name);
        if (!newName || newName === contextMenuTarget.name) return;

        const oldPath = contextMenuTarget.path;
        const newPath = oldPath.substring(0, oldPath.lastIndexOf('/') + 1) + newName;

        try {
            const endpoint = contextMenuTarget.type === 'directory' ? '/api/directory/rename' : '/api/file/rename';
            const response = await fetch(endpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    old_path: oldPath,
                    new_path: newPath
                })
            });

            if (!response.ok) throw new Error('Rename failed');

            showNotification(`Renamed to ${newName}`, 'success');
            loadFileTree();
        } catch (error) {
            console.error('Error renaming:', error);
            showNotification('Error renaming', 'danger');
        }
    }

    async function pasteItem() {
        if (!clipboard) return;

        const destDir = contextMenuTarget.path;
        const sourcePath = clipboard.path;
        const fileName = clipboard.name;
        const destPath = destDir + '/' + fileName;

        try {
            if (clipboard.operation === 'copy') {
                // Copy operation
                const response = await fetch('/api/file/copy', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        source: sourcePath,
                        destination: destPath
                    })
                });

                if (!response.ok) throw new Error('Copy failed');
                showNotification(`Copied ${fileName} to ${contextMenuTarget.name}`, 'success');
            } else if (clipboard.operation === 'move') {
                // Move operation
                const response = await fetch('/api/file/move', {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        source: sourcePath,
                        destination: destPath
                    })
                });

                if (!response.ok) throw new Error('Move failed');
                showNotification(`Moved ${fileName} to ${contextMenuTarget.name}`, 'success');
                clipboard = null; // Clear clipboard after move
            }

            loadFileTree();
        } catch (error) {
            console.error('Error pasting:', error);
            showNotification('Error pasting file', 'danger');
        }
    }

    async function deleteItem() {
        if (!confirm(`Are you sure you want to delete ${contextMenuTarget.name}?`)) {
            return;
        }

        try {
            let response;
            if (contextMenuTarget.type === 'directory') {
                response = await fetch(`/api/directory?path=${encodeURIComponent(contextMenuTarget.path)}&recursive=true`, {
                    method: 'DELETE'
                });
            } else {
                response = await fetch(`/api/file?path=${encodeURIComponent(contextMenuTarget.path)}`, {
                    method: 'DELETE'
                });
            }

            if (!response.ok) throw new Error('Delete failed');

            showNotification(`Deleted ${contextMenuTarget.name}`, 'success');
            loadFileTree();
        } catch (error) {
            console.error('Error deleting:', error);
            showNotification('Error deleting', 'danger');
        }
    }

    // ========================================================================
    // Notifications
    // ========================================================================

    function showNotification(message, type = 'info') {
        let toastContainer = document.getElementById('toastContainer');
        if (!toastContainer) {
            toastContainer = createToastContainer();
        }

        const toast = document.createElement('div');
        toast.className = `toast align-items-center text-white bg-${type} border-0`;
        toast.setAttribute('role', 'alert');
        toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">${message}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        `;

        toastContainer.appendChild(toast);

        const bsToast = new bootstrap.Toast(toast, { delay: 3000 });
        bsToast.show();

        toast.addEventListener('hidden.bs.toast', () => {
            toast.remove();
        });
    }

    function createToastContainer() {
        const container = document.createElement('div');
        container.id = 'toastContainer';
        container.className = 'toast-container position-fixed top-0 end-0 p-3';
        container.style.zIndex = '9999';
        document.body.appendChild(container);
        return container;
    }

    // ========================================================================
    // Initialization
    // ========================================================================

    function init() {
        initDarkMode();
        initEditor();
        loadFileTree();

        document.getElementById('saveBtn').addEventListener('click', saveFile);
        document.getElementById('deleteBtn').addEventListener('click', deleteFile);
        document.getElementById('newFileBtn').addEventListener('click', newFile);
        document.getElementById('newFolderBtn').addEventListener('click', createFolder);
        document.getElementById('darkModeToggle').addEventListener('click', toggleDarkMode);

        // Context menu actions
        document.querySelectorAll('.context-menu-item').forEach(item => {
            item.addEventListener('click', () => {
                const action = item.dataset.action;
                handleContextMenuAction(action);
                hideContextMenu();
            });
        });

        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                saveFile();
            }
        });

        console.log('Docenter with File Tree initialized');
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();

