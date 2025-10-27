/**
 * Notification Service
 * Provides a standardized way to show toast notifications
 * Wraps the showNotification function from ui-utils.js
 */

class NotificationService {
    /**
     * Show a success notification
     * @param {string} message - The message to display
     */
    static success(message) {
        if (window.showNotification) {
            window.showNotification(message, Config.NOTIFICATION_TYPES.SUCCESS);
        } else {
            Logger.warn('showNotification not available, falling back to console');
            console.log(`✅ ${message}`);
        }
    }

    /**
     * Show an error notification
     * @param {string} message - The message to display
     */
    static error(message) {
        if (window.showNotification) {
            window.showNotification(message, Config.NOTIFICATION_TYPES.ERROR);
        } else {
            Logger.warn('showNotification not available, falling back to console');
            console.error(`❌ ${message}`);
        }
    }

    /**
     * Show a warning notification
     * @param {string} message - The message to display
     */
    static warning(message) {
        if (window.showNotification) {
            window.showNotification(message, Config.NOTIFICATION_TYPES.WARNING);
        } else {
            Logger.warn('showNotification not available, falling back to console');
            console.warn(`⚠️ ${message}`);
        }
    }

    /**
     * Show an info notification
     * @param {string} message - The message to display
     */
    static info(message) {
        if (window.showNotification) {
            window.showNotification(message, Config.NOTIFICATION_TYPES.INFO);
        } else {
            Logger.warn('showNotification not available, falling back to console');
            console.info(`ℹ️ ${message}`);
        }
    }

    /**
     * Show a notification with a custom type
     * @param {string} message - The message to display
     * @param {string} type - The notification type (success, danger, warning, primary, etc.)
     */
    static show(message, type = 'primary') {
        if (window.showNotification) {
            window.showNotification(message, type);
        } else {
            Logger.warn('showNotification not available, falling back to console');
            console.log(`[${type.toUpperCase()}] ${message}`);
        }
    }
}

// Make NotificationService globally available
window.NotificationService = NotificationService;

