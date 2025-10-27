/**
 * Editor Module
 * Handles CodeMirror editor and markdown preview
 */

class MarkdownEditor {
    constructor(editorId, previewId, filenameInputId, readOnly = false) {
        this.editorElement = document.getElementById(editorId);
        this.previewElement = document.getElementById(previewId);
        this.filenameInput = document.getElementById(filenameInputId);
        this.currentFile = null;
        this.webdavClient = null;
        this.macroProcessor = new MacroProcessor(null); // Will be set later
        this.lastViewedStorageKey = 'lastViewedPage'; // localStorage key for tracking last viewed page
        this.readOnly = readOnly; // Whether editor is in read-only mode
        this.editor = null; // Will be initialized later
        this.isShowingCustomPreview = false; // Flag to prevent auto-update when showing binary files

        // Initialize loading spinners (will be created lazily when needed)
        this.editorSpinner = null;
        this.previewSpinner = null;

        // Only initialize CodeMirror if not in read-only mode (view mode)
        if (!readOnly) {
            this.initCodeMirror();
        }
        this.initMarkdown();
        this.initMermaid();
    }

    /**
     * Initialize CodeMirror
     */
    initCodeMirror() {
        // Determine theme based on dark mode
        const isDarkMode = document.body.classList.contains('dark-mode');
        const theme = isDarkMode ? 'monokai' : 'default';

        this.editor = CodeMirror(this.editorElement, {
            mode: 'markdown',
            theme: theme,
            lineNumbers: true,
            lineWrapping: true,
            autofocus: !this.readOnly, // Don't autofocus in read-only mode
            readOnly: this.readOnly, // Set read-only mode
            extraKeys: this.readOnly ? {} : {
                'Ctrl-S': () => this.save(),
                'Cmd-S': () => this.save()
            }
        });

        // Update preview on change with debouncing
        this.editor.on('change', TimingUtils.debounce(() => {
            this.updatePreview();
        }, Config.DEBOUNCE_DELAY));

        // Initial preview render
        setTimeout(() => {
            this.updatePreview();
        }, 100);

        // Sync scroll
        this.editor.on('scroll', () => {
            this.syncScroll();
        });

        // Listen for dark mode changes
        this.setupThemeListener();
    }

    /**
     * Setup listener for dark mode changes
     */
    setupThemeListener() {
        // Watch for dark mode class changes
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.attributeName === 'class') {
                    const isDarkMode = document.body.classList.contains('dark-mode');
                    const newTheme = isDarkMode ? 'monokai' : 'default';
                    this.editor.setOption('theme', newTheme);
                }
            });
        });

        observer.observe(document.body, { attributes: true });
    }

    /**
     * Initialize markdown parser
     */
    initMarkdown() {
        if (window.marked) {
            this.marked = window.marked;

            // Create custom renderer for images
            const renderer = new marked.Renderer();

            renderer.image = (token) => {
                // Handle both old API (string params) and new API (token object)
                let href, title, text;

                if (typeof token === 'object' && token !== null) {
                    // New API: token is an object
                    href = token.href || '';
                    title = token.title || '';
                    text = token.text || '';
                } else {
                    // Old API: separate parameters (href, title, text)
                    href = arguments[0] || '';
                    title = arguments[1] || '';
                    text = arguments[2] || '';
                }

                // Ensure all are strings
                href = String(href || '');
                title = String(title || '');
                text = String(text || '');

                Logger.debug(`Image renderer called with href="${href}", title="${title}", text="${text}"`);

                // Check if href contains binary data (starts with non-printable characters)
                if (href && href.length > 100 && /^[\x00-\x1F\x7F-\xFF]/.test(href)) {
                    Logger.error('Image href contains binary data - this should not happen!');
                    Logger.error('First 50 chars:', href.substring(0, 50));
                    // Return a placeholder image
                    return `<div class="alert alert-warning">⚠️ Invalid image data detected. Please re-upload the image.</div>`;
                }

                // Fix relative image paths to use WebDAV base URL
                if (href && !href.startsWith('http://') && !href.startsWith('https://') && !href.startsWith('data:')) {
                    // Get the directory of the current file
                    const currentDir = this.currentFile ? PathUtils.getParentPath(this.currentFile) : '';

                    // Resolve relative path
                    let imagePath = href;
                    if (href.startsWith('./')) {
                        // Relative to current directory
                        imagePath = PathUtils.joinPaths(currentDir, href.substring(2));
                    } else if (href.startsWith('../')) {
                        // Relative to parent directory
                        imagePath = PathUtils.joinPaths(currentDir, href);
                    } else if (!href.startsWith('/')) {
                        // Relative to current directory (no ./)
                        imagePath = PathUtils.joinPaths(currentDir, href);
                    } else {
                        // Absolute path from collection root
                        imagePath = href.substring(1); // Remove leading /
                    }

                    // Build WebDAV URL - ensure no double slashes
                    if (this.webdavClient && this.webdavClient.currentCollection) {
                        // Remove trailing slash from baseUrl if present
                        const baseUrl = this.webdavClient.baseUrl.endsWith('/')
                            ? this.webdavClient.baseUrl.slice(0, -1)
                            : this.webdavClient.baseUrl;

                        // Ensure imagePath doesn't start with /
                        const cleanImagePath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;

                        href = `${baseUrl}/${this.webdavClient.currentCollection}/${cleanImagePath}`;

                        Logger.debug(`Resolved image URL: ${href}`);
                    }
                }

                // Generate HTML directly
                const titleAttr = title ? ` title="${title}"` : '';
                const altAttr = text ? ` alt="${text}"` : '';
                return `<img src="${href}"${altAttr}${titleAttr}>`;
            };

            this.marked.setOptions({
                breaks: true,
                gfm: true,
                renderer: renderer,
                highlight: (code, lang) => {
                    if (lang && window.Prism.languages[lang]) {
                        return window.Prism.highlight(code, window.Prism.languages[lang], lang);
                    }
                    return code;
                }
            });
        } else {
            console.error('Marked library not found.');
        }
    }

    /**
     * Initialize Mermaid
     */
    initMermaid() {
        if (window.mermaid) {
            window.mermaid.initialize({
                startOnLoad: false,
                theme: document.body.classList.contains('dark-mode') ? 'dark' : 'default'
            });
        }
    }

    /**
     * Set WebDAV client
     */
    setWebDAVClient(client) {
        this.webdavClient = client;

        // Update macro processor with client
        if (this.macroProcessor) {
            this.macroProcessor.webdavClient = client;
        }
    }

    /**
     * Initialize loading spinners (lazy initialization)
     */
    initLoadingSpinners() {
        if (!this.editorSpinner && !this.readOnly && this.editorElement) {
            this.editorSpinner = new LoadingSpinner(this.editorElement, 'Loading file...');
        }
        if (!this.previewSpinner && this.previewElement) {
            this.previewSpinner = new LoadingSpinner(this.previewElement, 'Rendering preview...');
        }
    }

    /**
     * Load file
     */
    async loadFile(path) {
        try {
            // Initialize loading spinners if not already done
            this.initLoadingSpinners();

            // Show loading spinners
            if (this.editorSpinner) {
                this.editorSpinner.show('Loading file...');
            }
            if (this.previewSpinner) {
                this.previewSpinner.show('Loading preview...');
            }

            // Reset custom preview flag when loading text files
            this.isShowingCustomPreview = false;

            const content = await this.webdavClient.get(path);
            this.currentFile = path;

            // Update filename input if it exists
            if (this.filenameInput) {
                this.filenameInput.value = path;
            }

            // Update editor if it exists (edit mode)
            if (this.editor) {
                this.editor.setValue(content);
            }

            // Update preview with the loaded content
            await this.renderPreview(content);

            // Save as last viewed page
            this.saveLastViewedPage(path);

            // Hide loading spinners
            if (this.editorSpinner) {
                this.editorSpinner.hide();
            }
            if (this.previewSpinner) {
                this.previewSpinner.hide();
            }

            // No notification for successful file load - it's not critical
        } catch (error) {
            // Hide loading spinners on error
            if (this.editorSpinner) {
                this.editorSpinner.hide();
            }
            if (this.previewSpinner) {
                this.previewSpinner.hide();
            }

            console.error('Failed to load file:', error);
            if (window.showNotification) {
                window.showNotification('Failed to load file', 'danger');
            }
        }
    }

    /**
     * Save the last viewed page to localStorage
     * Stores per collection so different collections can have different last viewed pages
     */
    saveLastViewedPage(path) {
        if (!this.webdavClient || !this.webdavClient.currentCollection) {
            return;
        }
        const collection = this.webdavClient.currentCollection;
        const storageKey = `${this.lastViewedStorageKey}:${collection}`;
        localStorage.setItem(storageKey, path);
    }

    /**
     * Get the last viewed page from localStorage
     * Returns null if no page was previously viewed
     */
    getLastViewedPage() {
        if (!this.webdavClient || !this.webdavClient.currentCollection) {
            return null;
        }
        const collection = this.webdavClient.currentCollection;
        const storageKey = `${this.lastViewedStorageKey}:${collection}`;
        return localStorage.getItem(storageKey);
    }

    /**
     * Save file
     */
    async save() {
        const path = this.filenameInput.value.trim();
        if (!path) {
            if (window.showNotification) {
                window.showNotification('Please enter a filename', 'warning');
            }
            return;
        }

        const content = this.editor.getValue();

        try {
            await this.webdavClient.put(path, content);
            this.currentFile = path;

            if (window.showNotification) {
                window.showNotification('✅ Saved', 'success');
            }

            // Dispatch event to reload file tree
            if (window.eventBus) {
                window.eventBus.dispatch('file-saved', path);
            }
        } catch (error) {
            console.error('Failed to save file:', error);
            if (window.showNotification) {
                window.showNotification('Failed to save file', 'danger');
            }
        }
    }

    /**
     * Create new file
     */
    newFile() {
        this.currentFile = null;
        this.filenameInput.value = '';
        this.filenameInput.focus();
        this.editor.setValue('# New File\n\nStart typing...\n');
        this.updatePreview();
        // No notification needed - UI is self-explanatory
    }

    /**
     * Delete current file
     */
    async deleteFile() {
        if (!this.currentFile) {
            window.showNotification('No file selected', 'warning');
            return;
        }

        const confirmed = await window.ConfirmationManager.confirm(`Are you sure you want to delete ${this.currentFile}?`, 'Delete File', true);
        if (confirmed) {
            try {
                await this.webdavClient.delete(this.currentFile);
                window.showNotification(`Deleted ${this.currentFile}`, 'success');
                this.newFile();
                window.eventBus.dispatch('file-deleted');
            } catch (error) {
                console.error('Failed to delete file:', error);
                window.showNotification('Failed to delete file', 'danger');
            }
        }
    }

    /**
     * Convert JSX-style attributes to HTML attributes
     * Handles style={{...}} and boolean attributes like allowFullScreen={true}
     */
    convertJSXToHTML(content) {
        Logger.debug('Converting JSX to HTML...');

        // Convert style={{...}} to style="..."
        // This regex finds style={{...}} and converts the object notation to CSS string
        content = content.replace(/style=\{\{([^}]+)\}\}/g, (match, styleContent) => {
            Logger.debug(`Found JSX style: ${match}`);

            // Parse the object-like syntax and convert to CSS
            const cssRules = styleContent
                .split(',')
                .map(rule => {
                    const colonIndex = rule.indexOf(':');
                    if (colonIndex === -1) return '';

                    const key = rule.substring(0, colonIndex).trim();
                    const value = rule.substring(colonIndex + 1).trim();

                    if (!key || !value) return '';

                    // Convert camelCase to kebab-case (e.g., paddingTop -> padding-top)
                    const cssKey = key.replace(/([A-Z])/g, '-$1').toLowerCase();

                    // Remove quotes from value
                    let cssValue = value.replace(/^['"]|['"]$/g, '');

                    return `${cssKey}: ${cssValue}`;
                })
                .filter(rule => rule)
                .join('; ');

            Logger.debug(`Converted to CSS: style="${cssRules}"`);
            return `style="${cssRules}"`;
        });

        // Convert boolean attributes like allowFullScreen={true} to allowfullscreen
        content = content.replace(/(\w+)=\{true\}/g, (match, attrName) => {
            Logger.debug(`Found boolean attribute: ${match}`);
            // Convert camelCase to lowercase for HTML attributes
            const htmlAttr = attrName.toLowerCase();
            Logger.debug(`Converted to: ${htmlAttr}`);
            return htmlAttr;
        });

        // Remove attributes set to {false}
        content = content.replace(/\s+\w+=\{false\}/g, '');

        return content;
    }

    /**
     * Render preview from markdown content
     * Can be called with explicit content (for view mode) or from editor (for edit mode)
     */
    async renderPreview(markdownContent = null) {
        // Get markdown content from editor if not provided
        const markdown = markdownContent !== null ? markdownContent : (this.editor ? this.editor.getValue() : '');
        const previewDiv = this.previewElement;

        if (!markdown || !markdown.trim()) {
            previewDiv.innerHTML = `
                <div class="text-muted text-center mt-5">
                    <p>Start typing to see preview...</p>
                </div>
            `;
            return;
        }

        try {
            // Initialize loading spinners if not already done
            this.initLoadingSpinners();

            // Show preview loading spinner (only if not already shown by loadFile)
            if (this.previewSpinner && !this.previewSpinner.isVisible()) {
                this.previewSpinner.show('Rendering preview...');
            }

            // Step 0: Convert JSX-style syntax to HTML
            let processedContent = this.convertJSXToHTML(markdown);

            // Step 1: Process macros
            if (this.macroProcessor) {
                const processingResult = await this.macroProcessor.processMacros(processedContent);
                processedContent = processingResult.content;
            }

            // Step 2: Parse markdown to HTML
            if (!this.marked) {
                console.error("Markdown parser (marked) not initialized.");
                previewDiv.innerHTML = `<div class="alert alert-danger">Preview engine not loaded.</div>`;
                if (this.previewSpinner) {
                    this.previewSpinner.hide();
                }
                return;
            }

            let html = this.marked.parse(processedContent);

            // Replace mermaid code blocks
            html = html.replace(
                /<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g,
                (match, code) => {
                    const id = 'mermaid-' + Math.random().toString(36).substr(2, 9);
                    return `<div class="mermaid" id="${id}">${code.trim()}</div>`;
                }
            );

            previewDiv.innerHTML = html;

            // Apply syntax highlighting
            const codeBlocks = previewDiv.querySelectorAll('pre code');
            codeBlocks.forEach(block => {
                const languageClass = Array.from(block.classList)
                    .find(cls => cls.startsWith('language-'));
                if (languageClass && languageClass !== 'language-mermaid') {
                    if (window.Prism) {
                        window.Prism.highlightElement(block);
                    }
                }
            });

            // Render mermaid diagrams
            const mermaidElements = previewDiv.querySelectorAll('.mermaid');
            if (mermaidElements.length > 0 && window.mermaid) {
                try {
                    window.mermaid.contentLoaded();
                } catch (error) {
                    console.warn('Mermaid rendering error:', error);
                }
            }

            // Hide preview loading spinner after a small delay to ensure rendering is complete
            setTimeout(() => {
                if (this.previewSpinner) {
                    this.previewSpinner.hide();
                }
            }, 100);
        } catch (error) {
            console.error('Preview rendering error:', error);
            previewDiv.innerHTML = `
                <div class="alert alert-danger" role="alert">
                    <strong>Error rendering preview:</strong><br>
                    ${error.message}
                </div>
            `;

            // Hide loading spinner on error
            if (this.previewSpinner) {
                this.previewSpinner.hide();
            }
        }
    }

    /**
     * Update preview (backward compatibility wrapper)
     * Calls renderPreview with content from editor
     */
    async updatePreview() {
        // Skip auto-update if showing custom preview (e.g., binary files)
        if (this.isShowingCustomPreview) {
            Logger.debug('Skipping auto-update: showing custom preview');
            return;
        }

        if (this.editor) {
            await this.renderPreview();
        }
    }

    /**
     * Sync scroll between editor and preview
     */
    syncScroll() {
        if (!this.editor) return; // Skip if no editor (view mode)

        const scrollInfo = this.editor.getScrollInfo();
        const scrollPercent = scrollInfo.top / (scrollInfo.height - scrollInfo.clientHeight);

        const previewHeight = this.previewElement.scrollHeight - this.previewElement.clientHeight;
        this.previewElement.scrollTop = previewHeight * scrollPercent;
    }

    /**
     * Handle image upload
     */
    async uploadImage(file) {
        try {
            const filename = await this.webdavClient.uploadImage(file);
            const imageUrl = `/fs/${this.webdavClient.currentCollection}/images/${filename}`;
            const markdown = `![${file.name}](${imageUrl})`;

            // Insert at cursor
            this.editor.replaceSelection(markdown);

            if (window.showNotification) {
                window.showNotification('Image uploaded', 'success');
            }
        } catch (error) {
            console.error('Failed to upload image:', error);
            if (window.showNotification) {
                window.showNotification('Failed to upload image', 'danger');
            }
        }
    }

    /**
     * Get editor content
     */
    getValue() {
        return this.editor.getValue();
    }

    insertAtCursor(text) {
        const doc = this.editor.getDoc();
        const cursor = doc.getCursor();
        doc.replaceRange(text, cursor);
    }

    /**
     * Set editor content
     */
    setValue(content) {
        this.editor.setValue(content);
    }

    // Debounce function moved to TimingUtils in utils.js
}

// Export for use in other modules
window.MarkdownEditor = MarkdownEditor;

