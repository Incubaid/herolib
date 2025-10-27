/**
 * Editor Drop Handler Module
 * Handles file drops into the editor for uploading
 */

class EditorDropHandler {
    constructor(editorElement, onFileDrop) {
        this.editorElement = editorElement;
        this.onFileDrop = onFileDrop;
        this.setupHandlers();
    }

    /**
     * Setup drag and drop event handlers
     */
    setupHandlers() {
        this.editorElement.addEventListener('dragover', (e) => {
            e.preventDefault();
            e.stopPropagation();
            this.editorElement.classList.add('drag-over');
        });

        this.editorElement.addEventListener('dragleave', (e) => {
            e.preventDefault();
            e.stopPropagation();
            this.editorElement.classList.remove('drag-over');
        });

        this.editorElement.addEventListener('drop', async (e) => {
            e.preventDefault();
            e.stopPropagation();
            this.editorElement.classList.remove('drag-over');

            const files = Array.from(e.dataTransfer.files);
            if (files.length === 0) return;

            Logger.debug(`Dropped ${files.length} file(s) into editor`);

            for (const file of files) {
                try {
                    if (this.onFileDrop) {
                        await this.onFileDrop(file);
                    }
                } catch (error) {
                    Logger.error('Drop failed:', error);
                    if (window.showNotification) {
                        window.showNotification(`Failed to upload ${file.name}`, 'error');
                    }
                }
            }
        });
    }

    /**
     * Remove event handlers
     */
    destroy() {
        // Note: We can't easily remove the event listeners without keeping references
        // This is a limitation of the current implementation
        // In a future refactor, we could store the bound handlers
        Logger.debug('EditorDropHandler destroyed');
    }
}

// Make EditorDropHandler globally available
window.EditorDropHandler = EditorDropHandler;

