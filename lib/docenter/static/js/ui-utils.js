/**
 * UI Utilities Module
 * Toast notifications (kept for backward compatibility)
 *
 * Other utilities have been moved to separate modules:
 * - Context menu: context-menu.js
 * - File upload: file-upload.js
 * - Dark mode: dark-mode.js
 * - Collection selector: collection-selector.js
 * - Editor drop handler: editor-drop-handler.js
 */

/**
 * Show toast notification
 * @param {string} message - The message to display
 * @param {string} type - The notification type (info, success, error, warning, danger, primary)
 */
function showNotification(message, type = 'info') {
    const container = document.getElementById('toastContainer') || createToastContainer();

    const toast = document.createElement('div');
    const bgClass = type === 'error' ? 'danger' : type === 'success' ? 'success' : type === 'warning' ? 'warning' : 'primary';
    toast.className = `toast align-items-center text-white bg-${bgClass} border-0`;
    toast.setAttribute('role', 'alert');

    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">${message}</div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
    `;

    container.appendChild(toast);

    const bsToast = new bootstrap.Toast(toast, { delay: Config.TOAST_DURATION });
    bsToast.show();

    toast.addEventListener('hidden.bs.toast', () => {
        toast.remove();
    });
}

/**
 * Create the toast container if it doesn't exist
 * @returns {HTMLElement} The toast container element
 */
function createToastContainer() {
    const container = document.createElement('div');
    container.id = 'toastContainer';
    container.className = 'toast-container position-fixed top-0 end-0 p-3';
    container.style.zIndex = Config.TOAST_Z_INDEX;
    document.body.appendChild(container);
    return container;
}

// All other UI utilities have been moved to separate modules
// See the module list at the top of this file

// Make showNotification globally available
window.showNotification = showNotification;
