/**
 * HeroScript Editor JavaScript
 * Handles code editing, syntax highlighting, script execution, and real-time logging
 */

class ResizablePanel {
    constructor() {
        this.isResizing = false;
        this.resizeDirection = 'horizontal'; // 'horizontal' or 'vertical'
        this.startX = 0;
        this.startY = 0;
        this.startWidth = 0;
        this.startHeight = 0;
        this.editorPanel = null;
        this.logsPanel = null;
        this.horizontalHandle = null;
        this.verticalHandle = null;
        this.currentLayout = 'horizontal'; // 'horizontal' or 'vertical'
        this.init();
    }

    init() {
        this.editorPanel = document.getElementById('editor-panel');
        this.logsPanel = document.getElementById('logs-panel');
        this.horizontalHandle = document.getElementById('horizontal-resize-handle');
        this.verticalHandle = document.getElementById('vertical-resize-handle');

        if (!this.editorPanel || !this.logsPanel) {
            console.warn('ResizablePanel: Required elements not found');
            return;
        }

        this.detectLayout();
        this.setupResizeHandlers();
        this.loadSavedSizes();
        
        // Listen for window resize to detect layout changes
        window.addEventListener('resize', () => {
            this.detectLayout();
        });
    }

    detectLayout() {
        const containerStyle = window.getComputedStyle(this.editorPanel.parentElement);
        const isVertical = containerStyle.flexDirection === 'column';
        
        this.currentLayout = isVertical ? 'vertical' : 'horizontal';
        
        // Show/hide appropriate resize handles
        if (this.horizontalHandle) {
            this.horizontalHandle.style.display = isVertical ? 'none' : 'flex';
        }
        if (this.verticalHandle) {
            this.verticalHandle.style.display = isVertical ? 'flex' : 'none';
        }
    }

    setupResizeHandlers() {
        // Setup horizontal resize handle
        if (this.horizontalHandle) {
            this.horizontalHandle.addEventListener('mousedown', (e) => this.startResize(e, 'horizontal'));
            this.horizontalHandle.addEventListener('touchstart', (e) => this.startResize(e.touches[0], 'horizontal'));
            this.horizontalHandle.addEventListener('selectstart', (e) => e.preventDefault());
        }

        // Setup vertical resize handle
        if (this.verticalHandle) {
            this.verticalHandle.addEventListener('mousedown', (e) => this.startResize(e, 'vertical'));
            this.verticalHandle.addEventListener('touchstart', (e) => this.startResize(e.touches[0], 'vertical'));
            this.verticalHandle.addEventListener('selectstart', (e) => e.preventDefault());
        }

        // Global mouse/touch events
        document.addEventListener('mousemove', (e) => this.doResize(e));
        document.addEventListener('mouseup', () => this.stopResize());
        document.addEventListener('touchmove', (e) => this.doResize(e.touches[0]));
        document.addEventListener('touchend', () => this.stopResize());
    }

    startResize(e, direction) {
        this.isResizing = true;
        this.resizeDirection = direction;
        this.startX = e.clientX;
        this.startY = e.clientY;
        
        if (direction === 'horizontal') {
            this.startWidth = parseInt(window.getComputedStyle(this.logsPanel).width, 10);
            this.horizontalHandle?.classList.add('dragging');
        } else {
            this.startHeight = parseInt(window.getComputedStyle(this.logsPanel).height, 10);
            this.verticalHandle?.classList.add('dragging');
        }
        
        document.body.classList.add('resizing');
        e.preventDefault();
    }

    doResize(e) {
        if (!this.isResizing) return;

        if (this.resizeDirection === 'horizontal') {
            this.doHorizontalResize(e);
        } else {
            this.doVerticalResize(e);
        }
        
        e.preventDefault();
    }

    doHorizontalResize(e) {
        const deltaX = this.startX - e.clientX; // Reversed because we're resizing from right
        const newWidth = this.startWidth + deltaX;
        
        // Get container width for percentage calculation
        const containerWidth = this.editorPanel.parentElement.offsetWidth;
        const minWidth = 200; // Minimum width for logs panel
        const maxWidth = Math.min(600, containerWidth * 0.6); // Maximum 60% of container
        
        // Constrain the width
        const constrainedWidth = Math.max(minWidth, Math.min(maxWidth, newWidth));
        
        // Apply the new width
        this.logsPanel.style.width = constrainedWidth + 'px';
        
        // Update editor panel flex to fill remaining space
        const remainingWidth = containerWidth - constrainedWidth - 4; // 4px for resize handle
        this.editorPanel.style.flex = 'none';
        this.editorPanel.style.width = remainingWidth + 'px';
    }

    doVerticalResize(e) {
        const deltaY = e.clientY - this.startY;
        const newHeight = this.startHeight + deltaY;
        
        // Get container height for percentage calculation
        const containerHeight = this.editorPanel.parentElement.offsetHeight;
        const minHeight = 150; // Minimum height for logs panel
        const maxHeight = Math.min(400, containerHeight * 0.6); // Maximum 60% of container
        
        // Constrain the height
        const constrainedHeight = Math.max(minHeight, Math.min(maxHeight, newHeight));
        
        // Apply the new height
        this.logsPanel.style.height = constrainedHeight + 'px';
        
        // Update editor panel to fill remaining space
        const remainingHeight = containerHeight - constrainedHeight - 4; // 4px for resize handle
        this.editorPanel.style.flex = 'none';
        this.editorPanel.style.height = remainingHeight + 'px';
    }

    stopResize() {
        if (!this.isResizing) return;
        
        this.isResizing = false;
        
        // Remove visual feedback
        this.horizontalHandle?.classList.remove('dragging');
        this.verticalHandle?.classList.remove('dragging');
        document.body.classList.remove('resizing');
        
        // Save the current sizes
        this.saveSizes();
    }

    saveSizes() {
        if (this.currentLayout === 'horizontal') {
            const logsWidth = this.logsPanel.offsetWidth;
            const editorWidth = this.editorPanel.offsetWidth;
            localStorage.setItem('heroscript_logs_width', logsWidth.toString());
            localStorage.setItem('heroscript_editor_width', editorWidth.toString());
        } else {
            const logsHeight = this.logsPanel.offsetHeight;
            const editorHeight = this.editorPanel.offsetHeight;
            localStorage.setItem('heroscript_logs_height', logsHeight.toString());
            localStorage.setItem('heroscript_editor_height', editorHeight.toString());
        }
    }

    loadSavedSizes() {
        if (this.currentLayout === 'horizontal') {
            const savedLogsWidth = localStorage.getItem('heroscript_logs_width');
            const savedEditorWidth = localStorage.getItem('heroscript_editor_width');
            
            if (savedLogsWidth && savedEditorWidth) {
                const containerWidth = this.editorPanel.parentElement.offsetWidth;
                const logsWidth = parseInt(savedLogsWidth, 10);
                const editorWidth = parseInt(savedEditorWidth, 10);
                
                // Validate that saved sizes fit in current container
                if (logsWidth + editorWidth + 4 <= containerWidth) {
                    this.logsPanel.style.width = logsWidth + 'px';
                    this.editorPanel.style.flex = 'none';
                    this.editorPanel.style.width = editorWidth + 'px';
                }
            }
        } else {
            const savedLogsHeight = localStorage.getItem('heroscript_logs_height');
            const savedEditorHeight = localStorage.getItem('heroscript_editor_height');
            
            if (savedLogsHeight && savedEditorHeight) {
                const containerHeight = this.editorPanel.parentElement.offsetHeight;
                const logsHeight = parseInt(savedLogsHeight, 10);
                const editorHeight = parseInt(savedEditorHeight, 10);
                
                // Validate that saved sizes fit in current container
                if (logsHeight + editorHeight + 4 <= containerHeight) {
                    this.logsPanel.style.height = logsHeight + 'px';
                    this.editorPanel.style.flex = 'none';
                    this.editorPanel.style.height = editorHeight + 'px';
                }
            }
        }
    }

    resetToDefault() {
        if (this.currentLayout === 'horizontal') {
            // Reset to default horizontal sizes
            this.logsPanel.style.width = '350px';
            this.logsPanel.style.height = 'auto';
            this.editorPanel.style.flex = '1';
            this.editorPanel.style.width = 'auto';
            this.editorPanel.style.height = 'auto';
            
            // Clear saved horizontal sizes
            localStorage.removeItem('heroscript_logs_width');
            localStorage.removeItem('heroscript_editor_width');
        } else {
            // Reset to default vertical sizes
            this.logsPanel.style.height = '250px';
            this.logsPanel.style.width = '100%';
            this.editorPanel.style.flex = '1';
            this.editorPanel.style.height = 'auto';
            this.editorPanel.style.width = 'auto';
            
            // Clear saved vertical sizes
            localStorage.removeItem('heroscript_logs_height');
            localStorage.removeItem('heroscript_editor_height');
        }
    }
}

class HeroScriptEditor {
    constructor() {
        this.editor = null;
        this.logsContainer = null;
        this.autoScroll = true;
        this.redisConnection = null;
        this.currentSyntax = 'javascript';
        this.resizablePanel = null;
        this.init();
    }

    /**
     * Initialize the HeroScript editor
     */
    init() {
        this.setupEditor();
        this.setupLogging();
        this.setupEventListeners();
        this.connectToRedis();
        this.applySyntaxHighlighting();
        this.setupResizablePanels();
    }

    /**
     * Setup resizable panels
     */
    setupResizablePanels() {
        this.resizablePanel = new ResizablePanel();
    }

    /**
     * Setup the code editor
     */
    setupEditor() {
        this.editor = document.getElementById('script-editor');
        this.logsContainer = document.getElementById('logs-content');
        
        if (!this.editor || !this.logsContainer) {
            console.error('HeroScript: Required elements not found');
            return;
        }

        // Set initial content if empty
        if (!this.editor.value.trim()) {
            this.editor.value = this.getDefaultScript();
        }

        // Setup basic editor features
        this.setupEditorFeatures();
    }

    /**
     * Setup syntax highlighting
     */
    setupEditorFeatures() {
        // Handle syntax selection change
        const syntaxSelect = document.getElementById('syntax-select');
        if (syntaxSelect) {
            syntaxSelect.addEventListener('change', (e) => {
                this.currentSyntax = e.target.value;
                this.addLogEntry('user', `Syntax changed to ${this.currentSyntax}`, 'info');
            });
        }

        // Add tab support for better code editing
        this.editor.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                e.preventDefault();
                const start = this.editor.selectionStart;
                const end = this.editor.selectionEnd;
                
                // Insert tab character
                this.editor.value = this.editor.value.substring(0, start) +
                                   '    ' +
                                   this.editor.value.substring(end);
                
                // Move cursor
                this.editor.selectionStart = this.editor.selectionEnd = start + 4;
            }
        });

        // Auto-resize editor based on content
        this.editor.addEventListener('input', () => {
            this.autoResizeEditor();
        });

        // Note: Scroll sync not needed with contenteditable approach

        // Initial resize
        this.autoResizeEditor();
    }

    /**
     * Auto-resize editor to fit content
     */
    autoResizeEditor() {
        // Reset height to auto to get the correct scrollHeight
        this.editor.style.height = 'auto';
        
        // Set height based on content, with minimum height
        const minHeight = 500;
        const contentHeight = this.editor.scrollHeight;
        this.editor.style.height = Math.max(minHeight, contentHeight) + 'px';
    }

    /**
     * Apply syntax highlighting to the editor content
     */
    applySyntaxHighlighting() {
        // Replace textarea with a contenteditable div for better highlighting
        this.replaceTextareaWithHighlightedEditor();
        
        // Update highlighting when syntax changes
        const syntaxSelect = document.getElementById('syntax-select');
        if (syntaxSelect) {
            syntaxSelect.addEventListener('change', () => {
                this.currentSyntax = syntaxSelect.value;
                this.updateHighlighting();
            });
        }
        
        // Initial highlighting
        this.updateHighlighting();
    }

    /**
     * Replace textarea with a highlighted contenteditable div
     */
    replaceTextareaWithHighlightedEditor() {
        const container = document.getElementById('editor-container');
        if (!container || !this.editor) return;

        // Get current content
        const content = this.editor.value || this.getDefaultScript();
        
        // Create new highlighted editor
        const highlightedEditor = document.createElement('pre');
        highlightedEditor.id = 'highlighted-editor';
        highlightedEditor.className = 'hljs';
        highlightedEditor.style.cssText = `
            margin: 0;
            padding: 1.5rem;
            border: none;
            outline: none;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 16px;
            line-height: 1.6;
            background-color: var(--bg-primary) !important;
            color: var(--text-primary) !important;
            white-space: pre-wrap;
            word-wrap: break-word;
            overflow-wrap: break-word;
            min-height: 500px;
            height: 100%;
            width: 100%;
            box-sizing: border-box;
            resize: none;
        `;
        
        const codeElement = document.createElement('code');
        codeElement.className = `language-${this.currentSyntax}`;
        codeElement.contentEditable = 'true';
        codeElement.textContent = content;
        codeElement.style.cssText = `
            display: block;
            background: transparent !important;
            padding: 0;
            margin: 0;
            outline: none;
            border: none;
        `;
        
        highlightedEditor.appendChild(codeElement);
        
        // Replace the textarea
        this.editor.style.display = 'none';
        container.appendChild(highlightedEditor);
        
        // Update editor reference
        this.highlightedEditor = highlightedEditor;
        this.codeElement = codeElement;
        
        // Add event listeners for the new editor
        this.setupHighlightedEditorEvents();
    }

    /**
     * Setup event listeners for the highlighted editor
     */
    setupHighlightedEditorEvents() {
        if (!this.codeElement) return;
        
        // Update highlighting on input
        this.codeElement.addEventListener('input', () => {
            // Update the hidden textarea value
            this.editor.value = this.codeElement.textContent;
            
            // Debounce highlighting updates
            clearTimeout(this.highlightTimeout);
            this.highlightTimeout = setTimeout(() => {
                this.updateHighlighting();
            }, 300);
        });
        
        // Handle tab key for indentation
        this.codeElement.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                e.preventDefault();
                document.execCommand('insertText', false, '    ');
            }
        });
        
        // Focus the new editor
        this.codeElement.focus();
    }

    /**
     * Update syntax highlighting
     */
    updateHighlighting() {
        if (!this.codeElement || !window.hljs) return;

        const content = this.codeElement.textContent;
        
        // Store cursor position
        const selection = window.getSelection();
        const range = selection.rangeCount > 0 ? selection.getRangeAt(0) : null;
        const cursorOffset = range ? range.startOffset : 0;
        
        // Update language class
        this.codeElement.className = `language-${this.currentSyntax}`;
        
        // Apply highlighting
        window.hljs.highlightElement(this.codeElement);
        
        // Restore cursor position
        if (range && this.codeElement.firstChild) {
            try {
                const newRange = document.createRange();
                const textNode = this.codeElement.firstChild;
                const maxOffset = textNode.textContent ? textNode.textContent.length : 0;
                newRange.setStart(textNode, Math.min(cursorOffset, maxOffset));
                newRange.setEnd(textNode, Math.min(cursorOffset, maxOffset));
                selection.removeAllRanges();
                selection.addRange(newRange);
            } catch (e) {
                // Cursor restoration failed, that's okay
            }
        }
    }

    /**
     * Setup logging system
     */
    setupLogging() {
        this.addLogEntry('system', 'HeroScript Editor initialized', 'info');
        this.addLogEntry('system', 'Connecting to Redis queue: hero.gui.logs', 'info');
    }

    /**
     * Setup event listeners
     */
    setupEventListeners() {
        // Run script button
        const runButton = document.getElementById('run-script');
        if (runButton) {
            runButton.addEventListener('click', () => this.runScript());
        }

        // Clear logs button
        const clearButton = document.getElementById('clear-logs');
        if (clearButton) {
            clearButton.addEventListener('click', () => this.clearLogs());
        }

        // Save script button
        const saveButton = document.getElementById('save-script');
        if (saveButton) {
            saveButton.addEventListener('click', () => this.saveScript());
        }

        // Auto-scroll toggle
        const autoScrollButton = document.getElementById('auto-scroll');
        if (autoScrollButton) {
            autoScrollButton.addEventListener('click', () => this.toggleAutoScroll());
        }

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey)) {
                switch (e.key) {
                    case 'Enter':
                        e.preventDefault();
                        this.runScript();
                        break;
                    case 's':
                        e.preventDefault();
                        this.saveScript();
                        break;
                    case 'l':
                        e.preventDefault();
                        this.clearLogs();
                        break;
                }
            }
        });
    }

    /**
     * Connect to Redis queue for real-time logging
     */
    connectToRedis() {
        // Simulate Redis connection with WebSocket or Server-Sent Events
        // In a real implementation, you'd connect to a WebSocket endpoint
        // that subscribes to the Redis queue
        
        this.simulateRedisConnection();
    }

    /**
     * Simulate Redis connection for demo purposes
     */
    simulateRedisConnection() {
        // Update connection status
        this.updateConnectionStatus('connected');
        
        // Generate demo logs with different categories
        const logCategories = [
            { cat: 'system', messages: ['service started', 'health check ok', 'memory usage normal'], color: 'blue' },
            { cat: 'database', messages: ['connection established', 'query executed', 'backup completed'], color: 'green' },
            { cat: 'api', messages: ['request processed', 'rate limit applied', 'cache hit'], color: 'cyan' },
            { cat: 'security', messages: ['auth successful', 'token refreshed', 'access granted'], color: 'yellow' },
            { cat: 'error', messages: ['connection timeout', 'invalid request', 'service unavailable'], color: 'red' },
            { cat: 'warning', messages: ['high memory usage', 'slow query detected', 'retry attempt'], color: 'orange' }
        ];
        
        // Generate logs every 2-5 seconds
        setInterval(() => {
            if (Math.random() < 0.7) { // 70% chance
                const category = logCategories[Math.floor(Math.random() * logCategories.length)];
                const message = category.messages[Math.floor(Math.random() * category.messages.length)];
                this.addCompactLogEntry(category.cat, message, category.color);
            }
        }, Math.random() * 3000 + 2000); // 2-5 seconds
    }

    /**
     * Update connection status indicator
     */
    updateConnectionStatus(status) {
        const statusElement = document.getElementById('connection-status');
        if (!statusElement) return;

        statusElement.className = 'badge';
        switch (status) {
            case 'connected':
                statusElement.classList.add('bg-success');
                statusElement.textContent = 'Connected';
                break;
            case 'connecting':
                statusElement.classList.add('bg-warning');
                statusElement.textContent = 'Connecting...';
                break;
            case 'disconnected':
                statusElement.classList.add('bg-danger');
                statusElement.textContent = 'Disconnected';
                break;
        }
    }

    /**
     * Run the script in the editor
     */
    async runScript() {
        const script = this.editor.value.trim();
        if (!script) {
            this.addLogEntry('user', 'No script to execute', 'warning');
            return;
        }

        this.addLogEntry('user', 'Starting script execution...', 'info');
        
        try {
            // Simulate script execution
            await this.executeScript(script);
        } catch (error) {
            this.addLogEntry('user', `Script execution failed: ${error.message}`, 'error');
        }
    }

    /**
     * Execute the script (simulation)
     */
    async executeScript(script) {
        // Simulate script execution with delays
        const lines = script.split('\n').filter(line => line.trim());
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (!line || line.startsWith('//')) continue;
            
            // Simulate processing time
            await new Promise(resolve => setTimeout(resolve, 200 + Math.random() * 300));
            
            // Simulate different types of output
            if (line.includes('console.log')) {
                const match = line.match(/console\.log\(['"`](.+?)['"`]\)/);
                if (match) {
                    this.addLogEntry('script', match[1], 'info');
                }
            } else if (line.includes('error') || line.includes('Error')) {
                this.addLogEntry('script', `Error in line: ${line}`, 'error');
            } else if (line.includes('warn')) {
                this.addLogEntry('script', `Warning in line: ${line}`, 'warning');
            } else {
                this.addLogEntry('script', `Executed: ${line}`, 'success');
            }
        }
        
        this.addLogEntry('user', 'Script execution completed', 'success');
    }

    /**
     * Save the current script
     */
    saveScript() {
        const script = this.editor.value;
        
        // Simulate saving to server
        this.addLogEntry('user', 'Saving script...', 'info');
        
        setTimeout(() => {
            // Save to localStorage for demo
            localStorage.setItem('heroscript_content', script);
            localStorage.setItem('heroscript_syntax', this.currentSyntax);
            this.addLogEntry('user', 'Script saved successfully', 'success');
        }, 500);
    }

    /**
     * Load saved script
     */
    loadScript() {
        const savedScript = localStorage.getItem('heroscript_content');
        const savedSyntax = localStorage.getItem('heroscript_syntax');
        
        if (savedScript) {
            this.editor.value = savedScript;
            this.addLogEntry('user', 'Script loaded from storage', 'info');
        }
        
        if (savedSyntax) {
            this.currentSyntax = savedSyntax;
            const syntaxSelect = document.getElementById('syntax-select');
            if (syntaxSelect) {
                syntaxSelect.value = savedSyntax;
            }
        }
        
        // Auto-resize after loading
        this.autoResizeEditor();
    }

    /**
     * Clear all logs
     */
    clearLogs() {
        if (this.logsContainer) {
            this.logsContainer.innerHTML = '';
            this.addLogEntry('user', 'Logs cleared', 'info');
        }
    }

    /**
     * Toggle auto-scroll functionality
     */
    toggleAutoScroll() {
        this.autoScroll = !this.autoScroll;
        const button = document.getElementById('auto-scroll');
        if (button) {
            button.setAttribute('data-active', this.autoScroll.toString());
            button.innerHTML = this.autoScroll 
                ? '<i class="fas fa-arrow-down"></i> Auto-scroll'
                : '<i class="fas fa-pause"></i> Manual';
        }
        
        this.addLogEntry('user', `Auto-scroll ${this.autoScroll ? 'enabled' : 'disabled'}`, 'info');
    }

    /**
     * Add a compact log entry in the format: cat: loginfo
     */
    addCompactLogEntry(category, message, color = 'blue') {
        if (!this.logsContainer) return;

        const logEntry = document.createElement('div');
        logEntry.className = `log-entry compact new`;
        
        logEntry.innerHTML = `
            <span class="log-category" style="color: ${this.getLogColor(color)}">${this.escapeHtml(category)}:</span>
            <span class="log-message">${this.escapeHtml(message)}</span>
        `;

        this.logsContainer.appendChild(logEntry);

        // Remove 'new' class after animation
        setTimeout(() => {
            logEntry.classList.remove('new');
        }, 300);

        // Auto-scroll if enabled
        if (this.autoScroll) {
            this.scrollToBottom();
        }

        // Limit log entries to prevent memory issues
        const maxEntries = 500;
        const entries = this.logsContainer.children;
        if (entries.length > maxEntries) {
            for (let i = 0; i < entries.length - maxEntries; i++) {
                entries[i].remove();
            }
        }
    }

    /**
     * Add a log entry to the logs panel (legacy format for system messages)
     */
    addLogEntry(source, message, level = 'info') {
        // Use compact format for better display
        const colorMap = {
            'info': 'blue',
            'success': 'green',
            'warning': 'orange',
            'error': 'red',
            'debug': 'gray'
        };
        this.addCompactLogEntry(source, message, colorMap[level] || 'blue');
    }

    /**
     * Get color value for log categories
     */
    getLogColor(colorName) {
        const colors = {
            'red': '#ff4444',
            'blue': '#4488ff',
            'green': '#44ff44',
            'yellow': '#ffff44',
            'orange': '#ff8844',
            'cyan': '#44ffff',
            'purple': '#ff44ff',
            'gray': '#888888'
        };
        return colors[colorName] || colors['blue'];
    }

    /**
     * Scroll logs to bottom
     */
    scrollToBottom() {
        const container = document.getElementById('logs-container');
        if (container) {
            container.scrollTop = container.scrollHeight;
        }
    }

    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    /**
     * Get default script content
     */
    getDefaultScript() {
        return `// Welcome to HeroScript Editor!
// This is a powerful script execution environment

console.log('Hello from HeroScript!');

// Example: Simple loop with logging
for (let i = 1; i <= 5; i++) {
    console.log(\`Step \${i}: Processing...\`);
}

// Example: Conditional logic
if (new Date().getHours() < 12) {
    console.log('Good morning!');
} else {
    console.log('Good afternoon!');
}

console.log('Script execution completed!');

// Try editing this script and click "Run Script" to see it in action
// Use Ctrl+Enter to run, Ctrl+S to save, Ctrl+L to clear logs`;
    }
}

/**
 * Initialize HeroScript Editor when DOM is ready
 */
document.addEventListener('DOMContentLoaded', () => {
    // Only initialize if we're on the HeroScript page
    if (document.getElementById('script-editor')) {
        window.heroScriptEditor = new HeroScriptEditor();
        
        // Load any saved script
        window.heroScriptEditor.loadScript();
        
        console.log('HeroScript Editor initialized');
    }
});

/**
 * Export for external use
 */
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { HeroScriptEditor };
}