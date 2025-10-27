/**
 * Dark Mode Module
 * Manages dark mode theme switching and persistence
 */

class DarkMode {
    constructor() {
        this.isDark = localStorage.getItem(Config.STORAGE_KEYS.DARK_MODE) === 'true';
        this.apply();
    }

    /**
     * Toggle dark mode on/off
     */
    toggle() {
        this.isDark = !this.isDark;
        localStorage.setItem(Config.STORAGE_KEYS.DARK_MODE, this.isDark);
        this.apply();

        Logger.debug(`Dark mode ${this.isDark ? 'enabled' : 'disabled'}`);
    }

    /**
     * Apply the current dark mode state
     */
    apply() {
        if (this.isDark) {
            document.body.classList.add('dark-mode');
            const btn = document.getElementById('darkModeBtn');
            if (btn) btn.innerHTML = '<i class="bi bi-sun-fill"></i>';

            // Update mermaid theme
            if (window.mermaid) {
                mermaid.initialize({ theme: Config.MERMAID_THEME_DARK });
            }
        } else {
            document.body.classList.remove('dark-mode');
            const btn = document.getElementById('darkModeBtn');
            if (btn) btn.innerHTML = '<i class="bi bi-moon-fill"></i>';

            // Update mermaid theme
            if (window.mermaid) {
                mermaid.initialize({ theme: Config.MERMAID_THEME_LIGHT });
            }
        }
    }

    /**
     * Check if dark mode is currently enabled
     * @returns {boolean} True if dark mode is enabled
     */
    isEnabled() {
        return this.isDark;
    }

    /**
     * Enable dark mode
     */
    enable() {
        if (!this.isDark) {
            this.toggle();
        }
    }

    /**
     * Disable dark mode
     */
    disable() {
        if (this.isDark) {
            this.toggle();
        }
    }
}

// Make DarkMode globally available
window.DarkMode = DarkMode;

