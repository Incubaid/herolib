/**
 * File Upload Module
 * Handles file upload dialog for uploading files to the file tree
 */

/**
 * Show file upload dialog
 * @param {string} targetPath - The target directory path
 * @param {Function} onUpload - Callback function to handle file upload
 */
function showFileUploadDialog(targetPath, onUpload) {
    const input = document.createElement('input');
    input.type = 'file';
    input.multiple = true;

    input.addEventListener('change', async (e) => {
        const files = Array.from(e.target.files);
        if (files.length === 0) return;

        for (const file of files) {
            try {
                await onUpload(targetPath, file);
            } catch (error) {
                Logger.error('Upload failed:', error);
                if (window.showNotification) {
                    window.showNotification(`Failed to upload ${file.name}`, 'error');
                }
            }
        }
    });

    input.click();
}

// Make function globally available
window.showFileUploadDialog = showFileUploadDialog;

