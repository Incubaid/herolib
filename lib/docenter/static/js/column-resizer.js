/**
 * Column Resizer Module
 * Handles draggable column dividers
 */

class ColumnResizer {
    constructor() {
        this.resizer1 = document.getElementById('resizer1');
        this.resizer2 = document.getElementById('resizer2');
        this.sidebarPane = document.getElementById('sidebarPane');
        this.editorPane = document.getElementById('editorPane');
        this.previewPane = document.getElementById('previewPane');

        // Load saved dimensions
        this.loadDimensions();

        // Setup listeners
        this.setupResizers();
    }

    setupResizers() {
        this.resizer1.addEventListener('mousedown', (e) => this.startResize(e, 1));
        this.resizer2.addEventListener('mousedown', (e) => this.startResize(e, 2));
    }

    startResize(e, resizerId) {
        e.preventDefault();

        const startX = e.clientX;
        const startWidth1 = this.sidebarPane.offsetWidth;
        const startWidth2 = this.editorPane.offsetWidth;
        const startWidth3 = this.previewPane.offsetWidth;
        const containerWidth = this.sidebarPane.parentElement.offsetWidth;

        const resizer = resizerId === 1 ? this.resizer1 : this.resizer2;
        resizer.classList.add('dragging');

        // Remove max-width constraints during resize
        this.sidebarPane.style.maxWidth = 'none';
        this.editorPane.style.maxWidth = 'none';
        this.previewPane.style.maxWidth = 'none';

        const handleMouseMove = (moveEvent) => {
            const deltaX = moveEvent.clientX - startX;

            if (resizerId === 1) {
                // Resize sidebar and editor
                const newWidth1 = Math.max(150, Math.min(containerWidth * 0.4, startWidth1 + deltaX));

                this.sidebarPane.style.flex = `0 0 ${newWidth1}px`;
                this.sidebarPane.style.width = `${newWidth1}px`;

                // Editor takes remaining space minus preview
                this.editorPane.style.flex = `1 1 auto`;
            } else if (resizerId === 2) {
                // Resize editor and preview
                const newWidth2 = Math.max(250, Math.min(containerWidth * 0.8, startWidth2 + deltaX));

                this.editorPane.style.flex = `0 0 ${newWidth2}px`;
                this.editorPane.style.width = `${newWidth2}px`;

                // Preview takes remaining space
                this.previewPane.style.flex = `1 1 auto`;
            }

            // Dispatch resize event for editor refresh
            window.dispatchEvent(new Event('column-resize'));
        };

        const handleMouseUp = () => {
            resizer.classList.remove('dragging');
            document.removeEventListener('mousemove', handleMouseMove);
            document.removeEventListener('mouseup', handleMouseUp);

            // Save dimensions
            this.saveDimensions();

            // Trigger editor resize
            if (window.editor && window.editor.editor) {
                window.editor.editor.refresh();
            }
        };

        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
    }

    saveDimensions() {
        const dimensions = {
            sidebar: this.sidebarPane.offsetWidth,
            editor: this.editorPane.offsetWidth,
            preview: this.previewPane.offsetWidth
        };
        localStorage.setItem('columnDimensions', JSON.stringify(dimensions));
    }

    loadDimensions() {
        const saved = localStorage.getItem('columnDimensions');
        if (!saved) return;

        try {
            const { sidebar, editor, preview } = JSON.parse(saved);
            this.sidebarPane.style.flex = `0 0 ${sidebar}px`;
            this.editorPane.style.flex = `0 0 ${editor}px`;
        } catch (error) {
            console.error('Failed to load column dimensions:', error);
        }
    }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
    window.columnResizer = new ColumnResizer();
});