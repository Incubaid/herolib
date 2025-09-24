/**
 * Theme Management for Admin UI
 * Handles light/dark theme switching with localStorage persistence
 */

class ThemeManager {
    constructor() {
        this.currentTheme = this.getStoredTheme() || this.getPreferredTheme();
        this.init();
    }

    /**
     * Initialize theme manager
     */
    init() {
        this.applyTheme(this.currentTheme);
        this.createThemeToggle();
        this.bindEvents();
    }

    /**
     * Get theme from localStorage
     */
    getStoredTheme() {
        return localStorage.getItem('admin-theme');
    }

    /**
     * Get user's preferred theme from system
     */
    getPreferredTheme() {
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            return 'dark';
        }
        return 'light';
    }

    /**
     * Store theme preference
     */
    setStoredTheme(theme) {
        localStorage.setItem('admin-theme', theme);
    }

    /**
     * Apply theme to document
     */
    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        this.currentTheme = theme;
        this.setStoredTheme(theme);
        this.updateToggleButton();
    }

    /**
     * Toggle between light and dark themes
     */
    toggleTheme() {
        const newTheme = this.currentTheme === 'light' ? 'dark' : 'light';
        this.applyTheme(newTheme);
    }

    /**
     * Create theme toggle button
     */
    createThemeToggle() {
        const toggle = document.createElement('button');
        toggle.className = 'theme-toggle';
        toggle.id = 'theme-toggle';
        toggle.setAttribute('aria-label', 'Toggle theme');
        toggle.setAttribute('title', 'Toggle light/dark theme');
        
        document.body.appendChild(toggle);
    }

    /**
     * Update toggle button text and icon
     */
    updateToggleButton() {
        const toggle = document.getElementById('theme-toggle');
        if (toggle) {
            const icon = this.currentTheme === 'light' ? '🌙' : '☀️';
            const text = this.currentTheme === 'light' ? 'Dark' : 'Light';
            toggle.innerHTML = `${icon} ${text}`;
        }
    }

    /**
     * Bind event listeners
     */
    bindEvents() {
        // Theme toggle button click
        document.addEventListener('click', (e) => {
            if (e.target.id === 'theme-toggle') {
                this.toggleTheme();
            }
        });

        // Keyboard shortcut (Ctrl/Cmd + Shift + T)
        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'T') {
                e.preventDefault();
                this.toggleTheme();
            }
        });

        // Listen for system theme changes
        if (window.matchMedia) {
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                if (!this.getStoredTheme()) {
                    this.applyTheme(e.matches ? 'dark' : 'light');
                }
            });
        }
    }

    /**
     * Get current theme
     */
    getCurrentTheme() {
        return this.currentTheme;
    }

    /**
     * Set specific theme
     */
    setTheme(theme) {
        if (theme === 'light' || theme === 'dark') {
            this.applyTheme(theme);
        }
    }
}

/**
 * Mobile Menu Management
 */
class MobileMenuManager {
    constructor() {
        this.init();
    }

    init() {
        this.createMobileToggle();
        this.bindEvents();
    }

    createMobileToggle() {
        const toggle = document.createElement('button');
        toggle.className = 'mobile-menu-toggle';
        toggle.id = 'mobile-menu-toggle';
        toggle.innerHTML = '☰ Menu';
        toggle.setAttribute('aria-label', 'Toggle navigation menu');
        
        document.body.appendChild(toggle);
    }

    bindEvents() {
        document.addEventListener('click', (e) => {
            if (e.target.id === 'mobile-menu-toggle') {
                this.toggleMobileMenu();
            }
        });

        // Close menu when clicking outside
        document.addEventListener('click', (e) => {
            const sidebar = document.querySelector('.sidebar');
            const toggle = document.getElementById('mobile-menu-toggle');
            
            if (sidebar && sidebar.classList.contains('show') && 
                !sidebar.contains(e.target) && 
                e.target !== toggle) {
                this.closeMobileMenu();
            }
        });

        // Close menu on escape key
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeMobileMenu();
            }
        });
    }

    toggleMobileMenu() {
        const sidebar = document.querySelector('.sidebar');
        if (sidebar) {
            sidebar.classList.toggle('show');
        }
    }

    closeMobileMenu() {
        const sidebar = document.querySelector('.sidebar');
        if (sidebar) {
            sidebar.classList.remove('show');
        }
    }
}

/**
 * Initialize when DOM is ready
 */
document.addEventListener('DOMContentLoaded', () => {
    // Initialize theme manager
    window.themeManager = new ThemeManager();
    
    // Initialize mobile menu manager
    window.mobileMenuManager = new MobileMenuManager();
    
    // Add smooth scrolling to menu links
    document.querySelectorAll('.menu-leaf a').forEach(link => {
        link.addEventListener('click', (e) => {
            // Close mobile menu when link is clicked
            window.mobileMenuManager.closeMobileMenu();
        });
    });
    
    // Enhance menu collapse animations
    document.querySelectorAll('[data-bs-toggle="collapse"]').forEach(toggle => {
        toggle.addEventListener('click', (e) => {
            e.preventDefault();
            const target = document.querySelector(toggle.getAttribute('href'));
            if (target) {
                const isExpanded = toggle.getAttribute('aria-expanded') === 'true';
                toggle.setAttribute('aria-expanded', !isExpanded);
                target.classList.toggle('show');
            }
        });
    });
});

/**
 * Export for external use
 */
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { ThemeManager, MobileMenuManager };
}