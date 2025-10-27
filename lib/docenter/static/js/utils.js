/**
 * Utilities Module
 * Common utility functions used throughout the application
 */

/**
 * Path Utilities
 * Helper functions for path manipulation
 */
const PathUtils = {
    /**
     * Get the filename from a path
     * @param {string} path - The file path
     * @returns {string} The filename
     * @example PathUtils.getFileName('folder/subfolder/file.md') // 'file.md'
     */
    getFileName(path) {
        if (!path) return '';
        return path.split('/').pop();
    },

    /**
     * Get the parent directory path
     * @param {string} path - The file path
     * @returns {string} The parent directory path
     * @example PathUtils.getParentPath('folder/subfolder/file.md') // 'folder/subfolder'
     */
    getParentPath(path) {
        if (!path) return '';
        const lastSlash = path.lastIndexOf('/');
        return lastSlash === -1 ? '' : path.substring(0, lastSlash);
    },

    /**
     * Normalize a path by removing duplicate slashes
     * @param {string} path - The path to normalize
     * @returns {string} The normalized path
     * @example PathUtils.normalizePath('folder//subfolder///file.md') // 'folder/subfolder/file.md'
     */
    normalizePath(path) {
        if (!path) return '';
        return path.replace(/\/+/g, '/');
    },

    /**
     * Join multiple path segments
     * @param {...string} paths - Path segments to join
     * @returns {string} The joined path
     * @example PathUtils.joinPaths('folder', 'subfolder', 'file.md') // 'folder/subfolder/file.md'
     */
    joinPaths(...paths) {
        return PathUtils.normalizePath(paths.filter(p => p).join('/'));
    },

    /**
     * Get the file extension
     * @param {string} path - The file path
     * @returns {string} The file extension (without dot)
     * @example PathUtils.getExtension('file.md') // 'md'
     */
    getExtension(path) {
        if (!path) return '';
        const fileName = PathUtils.getFileName(path);
        const lastDot = fileName.lastIndexOf('.');
        return lastDot === -1 ? '' : fileName.substring(lastDot + 1);
    },

    /**
     * Check if a path is a descendant of another path
     * @param {string} path - The path to check
     * @param {string} ancestorPath - The potential ancestor path
     * @returns {boolean} True if path is a descendant of ancestorPath
     * @example PathUtils.isDescendant('folder/subfolder/file.md', 'folder') // true
     */
    isDescendant(path, ancestorPath) {
        if (!path || !ancestorPath) return false;
        return path.startsWith(ancestorPath + '/');
    },

    /**
     * Check if a file is a binary/non-editable file based on extension
     * @param {string} path - The file path
     * @returns {boolean} True if the file is binary/non-editable
     * @example PathUtils.isBinaryFile('image.png') // true
     * @example PathUtils.isBinaryFile('document.md') // false
     */
    isBinaryFile(path) {
        const extension = PathUtils.getExtension(path).toLowerCase();
        const binaryExtensions = [
            // Images
            'png', 'jpg', 'jpeg', 'gif', 'bmp', 'ico', 'svg', 'webp', 'tiff', 'tif',
            // Documents
            'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
            // Archives
            'zip', 'rar', '7z', 'tar', 'gz', 'bz2',
            // Executables
            'exe', 'dll', 'so', 'dylib', 'app',
            // Media
            'mp3', 'mp4', 'avi', 'mov', 'wmv', 'flv', 'wav', 'ogg',
            // Other binary formats
            'bin', 'dat', 'db', 'sqlite'
        ];
        return binaryExtensions.includes(extension);
    },

    /**
     * Check if a directory is an image directory based on its name
     * @param {string} path - The directory path
     * @returns {boolean} True if the directory is for images
     * @example PathUtils.isImageDirectory('images') // true
     * @example PathUtils.isImageDirectory('assets/images') // true
     * @example PathUtils.isImageDirectory('docs') // false
     */
    isImageDirectory(path) {
        const dirName = PathUtils.getFileName(path).toLowerCase();
        const imageDirectoryNames = [
            'images',
            'image',
            'img',
            'imgs',
            'pictures',
            'pics',
            'photos',
            'assets',
            'media',
            'static'
        ];
        return imageDirectoryNames.includes(dirName);
    },

    /**
     * Get a human-readable file type description
     * @param {string} path - The file path
     * @returns {string} The file type description
     * @example PathUtils.getFileType('image.png') // 'Image'
     */
    getFileType(path) {
        const extension = PathUtils.getExtension(path).toLowerCase();

        const imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'ico', 'svg', 'webp', 'tiff', 'tif'];
        const documentExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];
        const archiveExtensions = ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'];
        const mediaExtensions = ['mp3', 'mp4', 'avi', 'mov', 'wmv', 'flv', 'wav', 'ogg'];

        if (imageExtensions.includes(extension)) return 'Image';
        if (documentExtensions.includes(extension)) return 'Document';
        if (archiveExtensions.includes(extension)) return 'Archive';
        if (mediaExtensions.includes(extension)) return 'Media';
        if (extension === 'pdf') return 'PDF';

        return 'File';
    }
};

/**
 * DOM Utilities
 * Helper functions for DOM manipulation
 */
const DOMUtils = {
    /**
     * Create an element with optional class and attributes
     * @param {string} tag - The HTML tag name
     * @param {string} [className] - Optional class name(s)
     * @param {Object} [attributes] - Optional attributes object
     * @returns {HTMLElement} The created element
     */
    createElement(tag, className = '', attributes = {}) {
        const element = document.createElement(tag);
        if (className) {
            element.className = className;
        }
        Object.entries(attributes).forEach(([key, value]) => {
            element.setAttribute(key, value);
        });
        return element;
    },

    /**
     * Remove all children from an element
     * @param {HTMLElement} element - The element to clear
     */
    removeAllChildren(element) {
        while (element.firstChild) {
            element.removeChild(element.firstChild);
        }
    },

    /**
     * Toggle a class on an element
     * @param {HTMLElement} element - The element
     * @param {string} className - The class name
     * @param {boolean} [force] - Optional force add/remove
     */
    toggleClass(element, className, force) {
        if (force !== undefined) {
            element.classList.toggle(className, force);
        } else {
            element.classList.toggle(className);
        }
    },

    /**
     * Query selector with error handling
     * @param {string} selector - The CSS selector
     * @param {HTMLElement} [parent] - Optional parent element
     * @returns {HTMLElement|null} The found element or null
     */
    querySelector(selector, parent = document) {
        try {
            return parent.querySelector(selector);
        } catch (error) {
            Logger.error(`Invalid selector: ${selector}`, error);
            return null;
        }
    },

    /**
     * Query selector all with error handling
     * @param {string} selector - The CSS selector
     * @param {HTMLElement} [parent] - Optional parent element
     * @returns {NodeList|Array} The found elements or empty array
     */
    querySelectorAll(selector, parent = document) {
        try {
            return parent.querySelectorAll(selector);
        } catch (error) {
            Logger.error(`Invalid selector: ${selector}`, error);
            return [];
        }
    }
};

/**
 * Timing Utilities
 * Helper functions for timing and throttling
 */
const TimingUtils = {
    /**
     * Debounce a function
     * @param {Function} func - The function to debounce
     * @param {number} wait - The wait time in milliseconds
     * @returns {Function} The debounced function
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    /**
     * Throttle a function
     * @param {Function} func - The function to throttle
     * @param {number} wait - The wait time in milliseconds
     * @returns {Function} The throttled function
     */
    throttle(func, wait) {
        let inThrottle;
        return function executedFunction(...args) {
            if (!inThrottle) {
                func(...args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, wait);
            }
        };
    },

    /**
     * Delay execution
     * @param {number} ms - Milliseconds to delay
     * @returns {Promise} Promise that resolves after delay
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
};

/**
 * Download Utilities
 * Helper functions for file downloads
 */
const DownloadUtils = {
    /**
     * Trigger a download in the browser
     * @param {string|Blob} content - The content to download
     * @param {string} filename - The filename for the download
     */
    triggerDownload(content, filename) {
        const blob = content instanceof Blob ? content : new Blob([content]);
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    },

    /**
     * Download content as a blob
     * @param {Blob} blob - The blob to download
     * @param {string} filename - The filename for the download
     */
    downloadAsBlob(blob, filename) {
        DownloadUtils.triggerDownload(blob, filename);
    }
};

/**
 * Validation Utilities
 * Helper functions for input validation
 */
const ValidationUtils = {
    /**
     * Validate and sanitize a filename
     * @param {string} name - The filename to validate
     * @param {boolean} [isFolder=false] - Whether this is a folder name
     * @returns {Object} Validation result with {valid, sanitized, message}
     */
    validateFileName(name, isFolder = false) {
        const type = isFolder ? 'folder' : 'file';

        if (!name || name.trim().length === 0) {
            return { valid: false, sanitized: '', message: `${type} name cannot be empty` };
        }

        // Check for invalid characters using pattern from Config
        const validPattern = Config.FILENAME_PATTERN;

        if (!validPattern.test(name)) {
            const sanitized = ValidationUtils.sanitizeFileName(name);

            return {
                valid: false,
                sanitized,
                message: `Invalid characters in ${type} name. Only lowercase letters, numbers, and underscores allowed.\n\nSuggestion: "${sanitized}"`
            };
        }

        return { valid: true, sanitized: name, message: '' };
    },

    /**
     * Sanitize a filename by removing/replacing invalid characters
     * @param {string} name - The filename to sanitize
     * @returns {string} The sanitized filename
     */
    sanitizeFileName(name) {
        return name
            .toLowerCase()
            .replace(Config.FILENAME_INVALID_CHARS, '_')
            .replace(/_+/g, '_')
            .replace(/^_+|_+$/g, '');
    },

    /**
     * Check if a string is empty or whitespace
     * @param {string} str - The string to check
     * @returns {boolean} True if empty or whitespace
     */
    isEmpty(str) {
        return !str || str.trim().length === 0;
    },

    /**
     * Check if a value is a valid email
     * @param {string} email - The email to validate
     * @returns {boolean} True if valid email
     */
    isValidEmail(email) {
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailPattern.test(email);
    }
};

/**
 * String Utilities
 * Helper functions for string manipulation
 */
const StringUtils = {
    /**
     * Truncate a string to a maximum length
     * @param {string} str - The string to truncate
     * @param {number} maxLength - Maximum length
     * @param {string} [suffix='...'] - Suffix to add if truncated
     * @returns {string} The truncated string
     */
    truncate(str, maxLength, suffix = '...') {
        if (!str || str.length <= maxLength) return str;
        return str.substring(0, maxLength - suffix.length) + suffix;
    },

    /**
     * Capitalize the first letter of a string
     * @param {string} str - The string to capitalize
     * @returns {string} The capitalized string
     */
    capitalize(str) {
        if (!str) return '';
        return str.charAt(0).toUpperCase() + str.slice(1);
    },

    /**
     * Convert a string to kebab-case
     * @param {string} str - The string to convert
     * @returns {string} The kebab-case string
     */
    toKebabCase(str) {
        return str
            .replace(/([a-z])([A-Z])/g, '$1-$2')
            .replace(/[\s_]+/g, '-')
            .toLowerCase();
    }
};

// Make utilities globally available
window.PathUtils = PathUtils;
window.DOMUtils = DOMUtils;
window.TimingUtils = TimingUtils;
window.DownloadUtils = DownloadUtils;
window.ValidationUtils = ValidationUtils;
window.StringUtils = StringUtils;

