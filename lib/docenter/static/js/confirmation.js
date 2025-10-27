/**
 * Unified Modal Manager
 * Handles showing and hiding a Bootstrap modal for confirmations and prompts.
 * Uses a single reusable modal element to prevent double-opening issues.
 */
class ModalManager {
    constructor(modalId) {
        this.modalElement = document.getElementById(modalId);
        if (!this.modalElement) {
            console.error(`Modal element with id "${modalId}" not found`);
            return;
        }

        this.modal = new bootstrap.Modal(this.modalElement, {
            backdrop: 'static',
            keyboard: true
        });

        this.messageElement = this.modalElement.querySelector('#confirmationMessage');
        this.inputElement = this.modalElement.querySelector('#confirmationInput');
        this.confirmButton = this.modalElement.querySelector('#confirmButton');
        this.cancelButton = this.modalElement.querySelector('[data-bs-dismiss="modal"]');
        this.titleElement = this.modalElement.querySelector('.modal-title');
        this.currentResolver = null;
        this.isShowing = false;
    }

    /**
     * Show a confirmation dialog
     * @param {string} message - The message to display
     * @param {string} title - The dialog title
     * @param {boolean} isDangerous - Whether this is a dangerous action (shows red button)
     * @returns {Promise<boolean>} - Resolves to true if confirmed, false/null if cancelled
     */
    confirm(message, title = 'Confirmation', isDangerous = false) {
        return new Promise((resolve) => {
            // Prevent double-opening
            if (this.isShowing) {
                console.warn('Modal is already showing, ignoring duplicate request');
                resolve(null);
                return;
            }

            this.isShowing = true;
            this.currentResolver = resolve;
            this.titleElement.textContent = title;
            this.messageElement.textContent = message;
            this.inputElement.style.display = 'none';

            // Update button styling based on danger level
            if (isDangerous) {
                this.confirmButton.className = 'btn-flat btn-flat-danger';
                this.confirmButton.innerHTML = '<i class="bi bi-trash"></i> Delete';
            } else {
                this.confirmButton.className = 'btn-flat btn-flat-primary';
                this.confirmButton.innerHTML = '<i class="bi bi-check-circle"></i> OK';
            }

            // Set up event handlers
            this.confirmButton.onclick = (e) => {
                e.preventDefault();
                e.stopPropagation();
                this._handleConfirm(false);
            };

            // Handle modal hidden event for cleanup
            this.modalElement.addEventListener('hidden.bs.modal', () => {
                if (this.currentResolver) {
                    this._handleCancel();
                }
            }, { once: true });

            // Remove aria-hidden before showing to prevent accessibility warning
            this.modalElement.removeAttribute('aria-hidden');

            this.modal.show();

            // Focus confirm button after modal is shown
            this.modalElement.addEventListener('shown.bs.modal', () => {
                this.confirmButton.focus();
            }, { once: true });
        });
    }

    /**
     * Show a prompt dialog (input dialog)
     * @param {string} message - The message/label to display
     * @param {string} defaultValue - The default input value
     * @param {string} title - The dialog title
     * @returns {Promise<string|null>} - Resolves to input value if confirmed, null if cancelled
     */
    prompt(message, defaultValue = '', title = 'Input') {
        return new Promise((resolve) => {
            // Prevent double-opening
            if (this.isShowing) {
                console.warn('Modal is already showing, ignoring duplicate request');
                resolve(null);
                return;
            }

            this.isShowing = true;
            this.currentResolver = resolve;
            this.titleElement.textContent = title;
            this.messageElement.textContent = message;
            this.inputElement.style.display = 'block';
            this.inputElement.value = defaultValue;

            // Reset button to primary style for prompts
            this.confirmButton.className = 'btn-flat btn-flat-primary';
            this.confirmButton.innerHTML = '<i class="bi bi-check-circle"></i> OK';

            // Set up event handlers
            this.confirmButton.onclick = (e) => {
                e.preventDefault();
                e.stopPropagation();
                this._handleConfirm(true);
            };

            // Handle Enter key in input
            this.inputElement.onkeydown = (e) => {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    this._handleConfirm(true);
                }
            };

            // Handle modal hidden event for cleanup
            this.modalElement.addEventListener('hidden.bs.modal', () => {
                if (this.currentResolver) {
                    this._handleCancel();
                }
            }, { once: true });

            // Remove aria-hidden before showing to prevent accessibility warning
            this.modalElement.removeAttribute('aria-hidden');

            this.modal.show();

            // Focus and select input after modal is shown
            this.modalElement.addEventListener('shown.bs.modal', () => {
                this.inputElement.focus();
                this.inputElement.select();
            }, { once: true });
        });
    }

    _handleConfirm(isPrompt) {
        if (this.currentResolver) {
            const value = isPrompt ? this.inputElement.value.trim() : true;
            const resolver = this.currentResolver;
            this._cleanup();
            resolver(value);
        }
    }

    _handleCancel() {
        if (this.currentResolver) {
            const resolver = this.currentResolver;
            this._cleanup();
            resolver(null);
        }
    }

    _cleanup() {
        this.confirmButton.onclick = null;
        this.inputElement.onkeydown = null;
        this.currentResolver = null;
        this.isShowing = false;
        this.modal.hide();

        // Restore aria-hidden after modal is hidden
        this.modalElement.addEventListener('hidden.bs.modal', () => {
            this.modalElement.setAttribute('aria-hidden', 'true');
        }, { once: true });
    }
}

// Make it globally available
window.ConfirmationManager = new ModalManager('confirmationModal');
window.ModalManager = window.ConfirmationManager; // Alias for clarity
