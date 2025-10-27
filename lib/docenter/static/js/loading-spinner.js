/**
 * Loading Spinner Component
 * Displays a loading overlay with spinner for async operations
 */

class LoadingSpinner {
    /**
     * Create a loading spinner for a container
     * @param {string|HTMLElement} container - Container element or ID
     * @param {string} message - Optional loading message
     */
    constructor(container, message = 'Loading...') {
        this.container = typeof container === 'string'
            ? document.getElementById(container)
            : container;

        if (!this.container) {
            Logger.error('LoadingSpinner: Container not found');
            return;
        }

        this.message = message;
        this.overlay = null;
        this.isShowing = false;
        this.showTime = null; // Track when spinner was shown
        this.minDisplayTime = 300; // Minimum time to show spinner (ms)

        // Ensure container has position relative for absolute positioning
        const position = window.getComputedStyle(this.container).position;
        if (position === 'static') {
            this.container.style.position = 'relative';
        }
    }

    /**
     * Show the loading spinner
     * @param {string} message - Optional custom message
     */
    show(message = null) {
        if (this.isShowing) return;

        // Record when spinner was shown
        this.showTime = Date.now();

        // Create overlay if it doesn't exist
        if (!this.overlay) {
            this.overlay = this.createOverlay(message || this.message);
            this.container.appendChild(this.overlay);
        } else {
            // Update message if provided
            if (message) {
                const textElement = this.overlay.querySelector('.loading-text');
                if (textElement) {
                    textElement.textContent = message;
                }
            }
            this.overlay.classList.remove('hidden');
        }

        this.isShowing = true;
        Logger.debug(`Loading spinner shown: ${message || this.message}`);
    }

    /**
     * Hide the loading spinner
     * Ensures minimum display time for better UX
     */
    hide() {
        if (!this.isShowing || !this.overlay) return;

        // Calculate how long the spinner has been showing
        const elapsed = Date.now() - this.showTime;
        const remaining = Math.max(0, this.minDisplayTime - elapsed);

        // If minimum time hasn't elapsed, delay hiding
        if (remaining > 0) {
            setTimeout(() => {
                this.overlay.classList.add('hidden');
                this.isShowing = false;
                Logger.debug('Loading spinner hidden');
            }, remaining);
        } else {
            this.overlay.classList.add('hidden');
            this.isShowing = false;
            Logger.debug('Loading spinner hidden');
        }
    }

    /**
     * Remove the loading spinner from DOM
     */
    destroy() {
        if (this.overlay && this.overlay.parentNode) {
            this.overlay.parentNode.removeChild(this.overlay);
            this.overlay = null;
        }
        this.isShowing = false;
    }

    /**
     * Create the overlay element
     * @param {string} message - Loading message
     * @returns {HTMLElement} The overlay element
     */
    createOverlay(message) {
        const overlay = document.createElement('div');
        overlay.className = 'loading-overlay';

        const content = document.createElement('div');
        content.className = 'loading-content';

        const spinner = document.createElement('div');
        spinner.className = 'loading-spinner';

        const text = document.createElement('div');
        text.className = 'loading-text';
        text.textContent = message;

        content.appendChild(spinner);
        content.appendChild(text);
        overlay.appendChild(content);

        return overlay;
    }

    /**
     * Update the loading message
     * @param {string} message - New message
     */
    updateMessage(message) {
        this.message = message;
        if (this.overlay && this.isShowing) {
            const textElement = this.overlay.querySelector('.loading-text');
            if (textElement) {
                textElement.textContent = message;
            }
        }
    }

    /**
     * Check if spinner is currently showing
     * @returns {boolean} True if showing
     */
    isVisible() {
        return this.isShowing;
    }
}

// Make LoadingSpinner globally available
window.LoadingSpinner = LoadingSpinner;

