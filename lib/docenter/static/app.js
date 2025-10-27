// Docenter Application
(function () {
    'use strict';

    // State management
    let currentFile = null;
    let editor = null;
    let isScrollingSynced = true;
    let scrollTimeout = null;
    let isDarkMode = false;

    // Dark mode management
    function initDarkMode() {
        // Check for saved preference
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

        // Update mermaid theme
        mermaid.initialize({
            startOnLoad: false,
            theme: 'dark',
            securityLevel: 'loose'
        });

        // Re-render preview if there's content
        if (editor && editor.getValue()) {
            updatePreview();
        }
    }

    function disableDarkMode() {
        isDarkMode = false;
        document.body.classList.remove('dark-mode');
        // document.getElementById('darkModeIcon').textContent = '🌙';
        localStorage.setItem('darkMode', 'false');

        // Update mermaid theme
        mermaid.initialize({
            startOnLoad: false,
            theme: 'default',
            securityLevel: 'loose'
        });

        // Re-render preview if there's content
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
        sanitize: false, // Allow HTML in markdown
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

    // Handle drag and drop
    function setupDragAndDrop() {
        const editorElement = document.querySelector('.CodeMirror');

        // Prevent default drag behavior
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            editorElement.addEventListener(eventName, preventDefaults, false);
        });

        function preventDefaults(e) {
            e.preventDefault();
            e.stopPropagation();
        }

        // Highlight drop zone
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

        // Handle drop
        editorElement.addEventListener('drop', async (e) => {
            const files = e.dataTransfer.files;

            if (files.length === 0) return;

            // Filter for images only
            const imageFiles = Array.from(files).filter(file =>
                file.type.startsWith('image/')
            );

            if (imageFiles.length === 0) {
                showNotification('Please drop image files only', 'warning');
                return;
            }

            showNotification(`Uploading ${imageFiles.length} image(s)...`, 'info');

            // Upload images
            for (const file of imageFiles) {
                const url = await uploadImage(file);
                if (url) {
                    // Insert markdown image syntax at cursor
                    const cursor = editor.getCursor();
                    const imageMarkdown = `![${file.name}](${url})`;
                    editor.replaceRange(imageMarkdown, cursor);
                    editor.setCursor(cursor.line, cursor.ch + imageMarkdown.length);
                    showNotification(`Image uploaded: ${file.name}`, 'success');
                }
            }
        }, false);

        // Also handle paste events for images
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
        const textarea = document.getElementById('editor');
        editor = CodeMirror.fromTextArea(textarea, {
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

        // Update preview on change
        editor.on('change', debounce(updatePreview, 300));

        // Setup drag and drop after editor is ready
        setTimeout(setupDragAndDrop, 100);

        // Sync scroll
        editor.on('scroll', handleEditorScroll);
    }

    // Debounce function to limit update frequency
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

    // Update preview with markdown content
    async function updatePreview() {
        const content = editor.getValue();
        const previewDiv = document.getElementById('preview');

        if (!content.trim()) {
            previewDiv.innerHTML = `
                <div class="text-muted text-center mt-5">
                    <h4>Preview</h4>
                    <p>Start typing in the editor to see the preview</p>
                </div>
            `;
            return;
        }

        try {
            // Parse markdown to HTML
            let html = marked.parse(content);

            // Replace mermaid code blocks with div containers
            html = html.replace(
                /<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g,
                '<div class="mermaid">$1</div>'
            );

            previewDiv.innerHTML = html;

            // Apply syntax highlighting to code blocks
            const codeBlocks = previewDiv.querySelectorAll('pre code');
            codeBlocks.forEach(block => {
                // Detect language from class name
                const languageClass = Array.from(block.classList).find(cls => cls.startsWith('language-'));
                if (languageClass && languageClass !== 'language-mermaid') {
                    Prism.highlightElement(block);
                }
            });

            // Render mermaid diagrams
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

    // Handle editor scroll for synchronized scrolling
    function handleEditorScroll() {
        if (!isScrollingSynced) return;

        clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(() => {
            const editorScrollInfo = editor.getScrollInfo();
            const editorScrollPercentage = editorScrollInfo.top / (editorScrollInfo.height - editorScrollInfo.clientHeight);

            const previewPane = document.querySelector('.preview-pane');
            const previewScrollHeight = previewPane.scrollHeight - previewPane.clientHeight;

            if (previewScrollHeight > 0) {
                previewPane.scrollTop = editorScrollPercentage * previewScrollHeight;
            }
        }, 10);
    }

    // Load file list from server
    async function loadFileList() {
        try {
            const response = await fetch('/api/files');
            if (!response.ok) throw new Error('Failed to load file list');

            const files = await response.json();
            const fileListDiv = document.getElementById('fileList');

            if (files.length === 0) {
                fileListDiv.innerHTML = '<div class="text-muted p-2 small">No files yet</div>';
                return;
            }

            fileListDiv.innerHTML = files.map(file => `
                <a href="#" class="list-group-item list-group-item-action file-item" data-filename="${file.filename}">
                    <span class="file-name">${file.filename}</span>
                    <span class="file-size">${formatFileSize(file.size)}</span>
                </a>
            `).join('');

            // Add click handlers
            document.querySelectorAll('.file-item').forEach(item => {
                item.addEventListener('click', (e) => {
                    e.preventDefault();
                    const filename = item.dataset.filename;
                    loadFile(filename);
                });
            });
        } catch (error) {
            console.error('Error loading file list:', error);
            showNotification('Error loading file list', 'danger');
        }
    }

    // Load a specific file
    async function loadFile(filename) {
        try {
            const response = await fetch(`/api/files/${filename}`);
            if (!response.ok) throw new Error('Failed to load file');

            const data = await response.json();
            currentFile = data.filename;

            // Update UI
            document.getElementById('filenameInput').value = data.filename;
            editor.setValue(data.content);

            // Update active state in file list
            document.querySelectorAll('.file-item').forEach(item => {
                item.classList.toggle('active', item.dataset.filename === filename);
            });

            updatePreview();
            showNotification(`Loaded ${filename}`, 'success');
        } catch (error) {
            console.error('Error loading file:', error);
            showNotification('Error loading file', 'danger');
        }
    }

    // Save current file
    async function saveFile() {
        const filename = document.getElementById('filenameInput').value.trim();

        if (!filename) {
            showNotification('Please enter a filename', 'warning');
            return;
        }

        const content = editor.getValue();

        try {
            const response = await fetch('/api/files', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ filename, content })
            });

            if (!response.ok) throw new Error('Failed to save file');

            const result = await response.json();
            currentFile = result.filename;

            showNotification(`Saved ${result.filename}`, 'success');
            loadFileList();
        } catch (error) {
            console.error('Error saving file:', error);
            showNotification('Error saving file', 'danger');
        }
    }

    // Delete current file
    async function deleteFile() {
        const filename = document.getElementById('filenameInput').value.trim();

        if (!filename) {
            showNotification('No file selected', 'warning');
            return;
        }

        if (!confirm(`Are you sure you want to delete ${filename}?`)) {
            return;
        }

        try {
            const response = await fetch(`/api/files/${filename}`, {
                method: 'DELETE'
            });

            if (!response.ok) throw new Error('Failed to delete file');

            showNotification(`Deleted ${filename}`, 'success');

            // Clear editor
            currentFile = null;
            document.getElementById('filenameInput').value = '';
            editor.setValue('');
            updatePreview();

            loadFileList();
        } catch (error) {
            console.error('Error deleting file:', error);
            showNotification('Error deleting file', 'danger');
        }
    }

    // Create new file
    function newFile() {
        currentFile = null;
        document.getElementById('filenameInput').value = '';
        editor.setValue('');
        updatePreview();

        // Remove active state from all file items
        document.querySelectorAll('.file-item').forEach(item => {
            item.classList.remove('active');
        });

        showNotification('New file created', 'info');
    }

    // Format file size for display
    function formatFileSize(bytes) {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
    }

    // Show notification
    function showNotification(message, type = 'info') {
        // Create toast notification
        const toastContainer = document.getElementById('toastContainer') || createToastContainer();

        const toast = document.createElement('div');
        toast.className = `toast align-items-center text-white bg-${type} border-0`;
        toast.setAttribute('role', 'alert');
        toast.setAttribute('aria-live', 'assertive');
        toast.setAttribute('aria-atomic', 'true');

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

    // Create toast container if it doesn't exist
    function createToastContainer() {
        const container = document.createElement('div');
        container.id = 'toastContainer';
        container.className = 'toast-container position-fixed top-0 end-0 p-3';
        container.style.zIndex = '9999';
        document.body.appendChild(container);
        return container;
    }

    // Initialize application
    function init() {
        initDarkMode();
        initEditor();
        loadFileList();

        // Set up event listeners
        document.getElementById('saveBtn').addEventListener('click', saveFile);
        document.getElementById('deleteBtn').addEventListener('click', deleteFile);
        document.getElementById('newFileBtn').addEventListener('click', newFile);
        document.getElementById('darkModeToggle').addEventListener('click', toggleDarkMode);

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                e.preventDefault();
                saveFile();
            }
        });

        console.log('Docenter initialized');
    }

    // Start application when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();

