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
        const containerWidth = this.sidebarPane.parentElement.offsetWidth;

        const resizer = resizerId === 1 ? this.resizer1 : this.resizer2;
        resizer.classList.add('dragging');

        const handleMouseMove = (moveEvent) => {
            const deltaX = moveEvent.clientX - startX;

            if (resizerId === 1) {
                // Resize sidebar and editor
                const newWidth1 = Math.max(150, Math.min(40 * containerWidth / 100, startWidth1 + deltaX));
                const newWidth2 = startWidth2 - (newWidth1 - startWidth1);

                this.sidebarPane.style.flex = `0 0 ${newWidth1}px`;
                this.editorPane.style.flex = `1 1 ${newWidth2}px`;
            } else if (resizerId === 2) {
                // Resize editor and preview
                const newWidth2 = Math.max(250, Math.min(70 * containerWidth / 100, startWidth2 + deltaX));
                const containerFlex = this.sidebarPane.offsetWidth;

                this.editorPane.style.flex = `0 0 ${newWidth2}px`;
            }
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