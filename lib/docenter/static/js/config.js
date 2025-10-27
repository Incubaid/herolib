/**
 * Application Configuration
 * Centralized configuration values for the markdown editor
 */

const Config = {
    // ===== TIMING CONFIGURATION =====

    /**
     * Long-press threshold in milliseconds
     * Used for drag-and-drop detection in file tree
     */
    LONG_PRESS_THRESHOLD: 400,

    /**
     * Debounce delay in milliseconds
     * Used for editor preview updates
     */
    DEBOUNCE_DELAY: 300,

    /**
     * Toast notification duration in milliseconds
     */
    TOAST_DURATION: 3000,

    /**
     * Mouse move threshold in pixels
     * Used to detect if user is dragging vs clicking
     */
    MOUSE_MOVE_THRESHOLD: 5,

    // ===== UI CONFIGURATION =====

    /**
     * Drag preview width in pixels
     * Width of the drag ghost image during drag-and-drop
     */
    DRAG_PREVIEW_WIDTH: 200,

    /**
     * Tree indentation in pixels
     * Indentation per level in the file tree
     */
    TREE_INDENT_PX: 12,

    /**
     * Toast container z-index
     * Ensures toasts appear above other elements
     */
    TOAST_Z_INDEX: 9999,

    /**
     * Minimum sidebar width in pixels
     */
    MIN_SIDEBAR_WIDTH: 150,

    /**
     * Maximum sidebar width as percentage of container
     */
    MAX_SIDEBAR_WIDTH_PERCENT: 40,

    /**
     * Minimum editor width in pixels
     */
    MIN_EDITOR_WIDTH: 250,

    /**
     * Maximum editor width as percentage of container
     */
    MAX_EDITOR_WIDTH_PERCENT: 70,

    // ===== VALIDATION CONFIGURATION =====

    /**
     * Valid filename pattern
     * Only lowercase letters, numbers, underscores, and dots allowed
     */
    FILENAME_PATTERN: /^[a-z0-9_]+(\.[a-z0-9_]+)*$/,

    /**
     * Characters to replace in filenames
     * All invalid characters will be replaced with underscore
     */
    FILENAME_INVALID_CHARS: /[^a-z0-9_.]/g,

    // ===== STORAGE KEYS =====

    /**
     * LocalStorage keys used throughout the application
     */
    STORAGE_KEYS: {
        /**
         * Dark mode preference
         */
        DARK_MODE: 'darkMode',

        /**
         * Currently selected collection
         */
        SELECTED_COLLECTION: 'selectedCollection',

        /**
         * Last viewed page (per collection)
         * Actual key will be: lastViewedPage:{collection}
         */
        LAST_VIEWED_PAGE: 'lastViewedPage',

        /**
         * Column dimensions (sidebar, editor, preview widths)
         */
        COLUMN_DIMENSIONS: 'columnDimensions',

        /**
         * Sidebar collapsed state
         */
        SIDEBAR_COLLAPSED: 'sidebarCollapsed'
    },

    // ===== EDITOR CONFIGURATION =====

    /**
     * CodeMirror theme for light mode
     */
    EDITOR_THEME_LIGHT: 'default',

    /**
     * CodeMirror theme for dark mode
     */
    EDITOR_THEME_DARK: 'monokai',

    /**
     * Mermaid theme for light mode
     */
    MERMAID_THEME_LIGHT: 'default',

    /**
     * Mermaid theme for dark mode
     */
    MERMAID_THEME_DARK: 'dark',

    // ===== FILE TREE CONFIGURATION =====

    /**
     * Default content for new files
     */
    DEFAULT_FILE_CONTENT: '# New File\n\n',

    /**
     * Default filename for new files
     */
    DEFAULT_NEW_FILENAME: 'new_file.md',

    /**
     * Default folder name for new folders
     */
    DEFAULT_NEW_FOLDERNAME: 'new_folder',

    // ===== WEBDAV CONFIGURATION =====

    /**
     * WebDAV base URL
     * Since we're on the same server, use relative path
     */
    WEBDAV_BASE_URL: '/fs/',

    /**
     * PROPFIND depth for file tree loading
     */
    PROPFIND_DEPTH: 'infinity',

    // ===== DRAG AND DROP CONFIGURATION =====

    /**
     * Drag preview opacity
     */
    DRAG_PREVIEW_OPACITY: 0.8,

    /**
     * Dragging item opacity
     */
    DRAGGING_OPACITY: 0.4,

    /**
     * Drag preview offset X in pixels
     */
    DRAG_PREVIEW_OFFSET_X: 10,

    /**
     * Drag preview offset Y in pixels
     */
    DRAG_PREVIEW_OFFSET_Y: 10,

    // ===== NOTIFICATION TYPES =====

    /**
     * Bootstrap notification type mappings
     */
    NOTIFICATION_TYPES: {
        SUCCESS: 'success',
        ERROR: 'danger',
        WARNING: 'warning',
        INFO: 'primary'
    }
};

// Make Config globally available
window.Config = Config;

