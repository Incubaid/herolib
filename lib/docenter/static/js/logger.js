/**
 * Logger Module
 * Provides structured logging with different levels
 * Can be configured to show/hide different log levels
 */

class Logger {
    /**
     * Log levels
     */
    static LEVELS = {
        DEBUG: 0,
        INFO: 1,
        WARN: 2,
        ERROR: 3,
        NONE: 4
    };

    /**
     * Current log level
     * Set to DEBUG by default, can be changed via setLevel()
     */
    static currentLevel = Logger.LEVELS.DEBUG;

    /**
     * Enable/disable logging
     */
    static enabled = true;

    /**
     * Set the minimum log level
     * @param {number} level - One of Logger.LEVELS
     */
    static setLevel(level) {
        if (typeof level === 'number' && level >= 0 && level <= 4) {
            Logger.currentLevel = level;
        }
    }

    /**
     * Enable or disable logging
     * @param {boolean} enabled - Whether to enable logging
     */
    static setEnabled(enabled) {
        Logger.enabled = enabled;
    }

    /**
     * Log a debug message
     * @param {string} message - The message to log
     * @param {...any} args - Additional arguments to log
     */
    static debug(message, ...args) {
        if (!Logger.enabled || Logger.currentLevel > Logger.LEVELS.DEBUG) {
            return;
        }
        console.log(`[DEBUG] ${message}`, ...args);
    }

    /**
     * Log an info message
     * @param {string} message - The message to log
     * @param {...any} args - Additional arguments to log
     */
    static info(message, ...args) {
        if (!Logger.enabled || Logger.currentLevel > Logger.LEVELS.INFO) {
            return;
        }
        console.info(`[INFO] ${message}`, ...args);
    }

    /**
     * Log a warning message
     * @param {string} message - The message to log
     * @param {...any} args - Additional arguments to log
     */
    static warn(message, ...args) {
        if (!Logger.enabled || Logger.currentLevel > Logger.LEVELS.WARN) {
            return;
        }
        console.warn(`[WARN] ${message}`, ...args);
    }

    /**
     * Log an error message
     * @param {string} message - The message to log
     * @param {...any} args - Additional arguments to log
     */
    static error(message, ...args) {
        if (!Logger.enabled || Logger.currentLevel > Logger.LEVELS.ERROR) {
            return;
        }
        console.error(`[ERROR] ${message}`, ...args);
    }

    /**
     * Log a message with a custom prefix
     * @param {string} prefix - The prefix to use
     * @param {string} message - The message to log
     * @param {...any} args - Additional arguments to log
     */
    static log(prefix, message, ...args) {
        if (!Logger.enabled) {
            return;
        }
        console.log(`[${prefix}] ${message}`, ...args);
    }

    /**
     * Group related log messages
     * @param {string} label - The group label
     */
    static group(label) {
        if (!Logger.enabled) {
            return;
        }
        console.group(label);
    }

    /**
     * End a log group
     */
    static groupEnd() {
        if (!Logger.enabled) {
            return;
        }
        console.groupEnd();
    }

    /**
     * Log a table (useful for arrays of objects)
     * @param {any} data - The data to display as a table
     */
    static table(data) {
        if (!Logger.enabled) {
            return;
        }
        console.table(data);
    }

    /**
     * Start a timer
     * @param {string} label - The timer label
     */
    static time(label) {
        if (!Logger.enabled) {
            return;
        }
        console.time(label);
    }

    /**
     * End a timer and log the elapsed time
     * @param {string} label - The timer label
     */
    static timeEnd(label) {
        if (!Logger.enabled) {
            return;
        }
        console.timeEnd(label);
    }
}

// Make Logger globally available
window.Logger = Logger;

// Set default log level based on environment
// In production, you might want to set this to WARN or ERROR
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    Logger.setLevel(Logger.LEVELS.DEBUG);
} else {
    Logger.setLevel(Logger.LEVELS.INFO);
}

