/**
 * Context Menu Module
 * Handles the right-click context menu for file tree items
 */

/**
 * Show context menu at specified position
 * @param {number} x - X coordinate
 * @param {number} y - Y coordinate
 * @param {Object} target - Target object with path and isDir properties
 */
function showContextMenu(x, y, target) {
    const menu = document.getElementById('contextMenu');
    if (!menu) return;

    // Store target data
    menu.dataset.targetPath = target.path;
    menu.dataset.targetIsDir = target.isDir;

    // Show/hide menu items based on target type
    const items = {
        'new-file': target.isDir,
        'new-folder': target.isDir,
        'upload': target.isDir,
        'download': true,
        'paste': target.isDir && window.fileTreeActions?.clipboard,
        'open': !target.isDir
    };

    Object.entries(items).forEach(([action, show]) => {
        const item = menu.querySelector(`[data-action="${action}"]`);
        if (item) {
            item.style.display = show ? 'flex' : 'none';
        }
    });

    // Position menu
    menu.style.display = 'block';
    menu.style.left = x + 'px';
    menu.style.top = y + 'px';

    // Adjust if off-screen
    setTimeout(() => {
        const rect = menu.getBoundingClientRect();
        if (rect.right > window.innerWidth) {
            menu.style.left = (window.innerWidth - rect.width - 10) + 'px';
        }
        if (rect.bottom > window.innerHeight) {
            menu.style.top = (window.innerHeight - rect.height - 10) + 'px';
        }
    }, 0);
}

/**
 * Hide the context menu
 */
function hideContextMenu() {
    const menu = document.getElementById('contextMenu');
    if (menu) {
        menu.style.display = 'none';
    }
}

// Combined click handler for context menu and outside clicks
document.addEventListener('click', async (e) => {
    const menuItem = e.target.closest('.context-menu-item');

    if (menuItem) {
        // Handle context menu item click
        const action = menuItem.dataset.action;
        const menu = document.getElementById('contextMenu');
        const targetPath = menu.dataset.targetPath;
        const isDir = menu.dataset.targetIsDir === 'true';

        hideContextMenu();

        if (window.fileTreeActions) {
            await window.fileTreeActions.execute(action, targetPath, isDir);
        }
    } else if (!e.target.closest('#contextMenu') && !e.target.closest('.tree-node')) {
        // Hide on outside click
        hideContextMenu();
    }
});

// Make functions globally available
window.showContextMenu = showContextMenu;
window.hideContextMenu = hideContextMenu;

