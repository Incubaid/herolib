/**
 * Collection Selector Module
 * Manages the collection dropdown selector and persistence
 */

class CollectionSelector {
    constructor(selectId, webdavClient) {
        this.select = document.getElementById(selectId);
        this.webdavClient = webdavClient;
        this.onChange = null;
        this.storageKey = Config.STORAGE_KEYS.SELECTED_COLLECTION;
    }

    /**
     * Load collections from WebDAV and populate the selector
     */
    async load() {
        try {
            const collections = await this.webdavClient.getCollections();
            this.select.innerHTML = '';

            if (collections.length === 0) {
                // No collections found - show placeholder
                const option = document.createElement('option');
                option.value = '';
                option.textContent = 'No collections - Click + to create one';
                option.disabled = true;
                option.selected = true;
                this.select.appendChild(option);
                this.select.disabled = true;

                Logger.debug('No collections found');

                // Show a helpful notification
                if (window.showNotification) {
                    window.showNotification('No collections found. Click the + button to create your first collection!', 'info');
                }
                return;
            }

            // Enable the select if it was disabled
            this.select.disabled = false;

            collections.forEach(collection => {
                const option = document.createElement('option');
                option.value = collection;
                option.textContent = collection;
                this.select.appendChild(option);
            });

            // Determine which collection to select (priority: URL > localStorage > first)
            let collectionToSelect = collections[0]; // Default to first

            // Check URL first (highest priority)
            const urlCollection = this.getCollectionFromURL();
            if (urlCollection && collections.includes(urlCollection)) {
                collectionToSelect = urlCollection;
                Logger.info(`Using collection from URL: ${urlCollection}`);
            } else {
                // Fall back to localStorage
                const savedCollection = localStorage.getItem(this.storageKey);
                if (savedCollection && collections.includes(savedCollection)) {
                    collectionToSelect = savedCollection;
                    Logger.info(`Using collection from localStorage: ${savedCollection}`);
                }
            }

            this.select.value = collectionToSelect;
            this.webdavClient.setCollection(collectionToSelect);
            if (this.onChange) {
                this.onChange(collectionToSelect);
            }

            // Add change listener
            this.select.addEventListener('change', () => {
                const collection = this.select.value;
                // Save to localStorage
                localStorage.setItem(this.storageKey, collection);
                this.webdavClient.setCollection(collection);

                Logger.info(`Collection changed to: ${collection}`);

                // Update URL to reflect collection change
                this.updateURLForCollection(collection);

                if (this.onChange) {
                    this.onChange(collection);
                }
            });

            Logger.debug(`Loaded ${collections.length} collections`);
        } catch (error) {
            Logger.error('Failed to load collections:', error);
            if (window.showNotification) {
                window.showNotification('Failed to load collections', 'error');
            }
        }
    }

    /**
     * Get the currently selected collection
     * @returns {string} The collection name
     */
    getCurrentCollection() {
        return this.select.value;
    }

    /**
     * Set the collection to a specific value
     * @param {string} collection - The collection name to set
     */
    async setCollection(collection) {
        const collections = Array.from(this.select.options).map(opt => opt.value);
        if (collections.includes(collection)) {
            this.select.value = collection;
            localStorage.setItem(this.storageKey, collection);
            this.webdavClient.setCollection(collection);

            Logger.info(`Collection set to: ${collection}`);

            // Update URL to reflect collection change
            this.updateURLForCollection(collection);

            if (this.onChange) {
                this.onChange(collection);
            }
        } else {
            Logger.warn(`Collection "${collection}" not found in available collections`);
        }
    }

    /**
     * Update the browser URL to reflect the current collection
     * @param {string} collection - The collection name
     */
    updateURLForCollection(collection) {
        // Get current URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        const isEditMode = urlParams.get('edit') === 'true';

        // Build new URL with collection
        let url = `/${collection}/`;
        if (isEditMode) {
            url += '?edit=true';
        }

        // Use pushState to update URL without reloading
        window.history.pushState({ collection, filePath: null }, '', url);
        Logger.debug(`Updated URL to: ${url}`);
    }

    /**
     * Extract collection name from current URL
     * URL format: /<collection>/ or /<collection>/<file_path>
     * @returns {string|null} The collection name or null if not found
     */
    getCollectionFromURL() {
        const pathname = window.location.pathname;
        const parts = pathname.split('/').filter(p => p); // Remove empty parts

        if (parts.length === 0) {
            return null;
        }

        // First part is the collection
        return parts[0];
    }
}

// Make CollectionSelector globally available
window.CollectionSelector = CollectionSelector;

