/**
 * Sidebar Toggle Module
 * Manages sidebar collapse/expand functionality with localStorage persistence
 */

class SidebarToggle {
    constructor(sidebarId, toggleButtonId) {
        this.sidebar = document.getElementById(sidebarId);
        this.toggleButton = document.getElementById(toggleButtonId);
        this.storageKey = Config.STORAGE_KEYS.SIDEBAR_COLLAPSED || 'sidebarCollapsed';
        this.isCollapsed = localStorage.getItem(this.storageKey) === 'true';

        this.init();
    }

    /**
     * Initialize the sidebar toggle
     */
    init() {
        // Apply initial state
        this.apply();

        // Setup toggle button click handler
        if (this.toggleButton) {
            this.toggleButton.addEventListener('click', () => {
                this.toggle();
            });
        }

        // Make mini sidebar clickable to expand
        if (this.sidebar) {
            this.sidebar.addEventListener('click', (e) => {
                // Only expand if sidebar is collapsed and click is on the mini sidebar itself
                // (not on the file tree content when expanded)
                if (this.isCollapsed) {
                    this.expand();
                }
            });

            // Add cursor pointer when collapsed
            this.sidebar.style.cursor = 'default';
        }

        Logger.debug(`Sidebar initialized: ${this.isCollapsed ? 'collapsed' : 'expanded'}`);
    }

    /**
     * Toggle sidebar state
     */
    toggle() {
        this.isCollapsed = !this.isCollapsed;
        localStorage.setItem(this.storageKey, this.isCollapsed);
        this.apply();

        Logger.debug(`Sidebar ${this.isCollapsed ? 'collapsed' : 'expanded'}`);
    }

    /**
     * Apply the current sidebar state
     */
    apply() {
        if (this.sidebar) {
            if (this.isCollapsed) {
                this.sidebar.classList.add('collapsed');
                this.sidebar.style.cursor = 'pointer'; // Make mini sidebar clickable
            } else {
                this.sidebar.classList.remove('collapsed');
                this.sidebar.style.cursor = 'default'; // Normal cursor when expanded
            }
        }

        // Update toggle button icon
        if (this.toggleButton) {
            const icon = this.toggleButton.querySelector('i');
            if (icon) {
                if (this.isCollapsed) {
                    icon.className = 'bi bi-layout-sidebar-inset-reverse';
                } else {
                    icon.className = 'bi bi-layout-sidebar';
                }
            }
        }
    }

    /**
     * Collapse the sidebar
     */
    collapse() {
        if (!this.isCollapsed) {
            this.toggle();
        }
    }

    /**
     * Expand the sidebar
     */
    expand() {
        if (this.isCollapsed) {
            this.toggle();
        }
    }

    /**
     * Check if sidebar is currently collapsed
     * @returns {boolean} True if sidebar is collapsed
     */
    isCollapsedState() {
        return this.isCollapsed;
    }
}

// Make SidebarToggle globally available
window.SidebarToggle = SidebarToggle;

