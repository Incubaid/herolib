/**
 * Event Bus Module
 * Provides a centralized event system for application-wide communication
 * Allows components to communicate without tight coupling
 */

class EventBus {
    constructor() {
        /**
         * Map of event names to arrays of listener functions
         * @type {Object.<string, Function[]>}
         */
        this.listeners = {};
    }

    /**
     * Register an event listener
     * @param {string} event - The event name to listen for
     * @param {Function} callback - The function to call when the event is dispatched
     * @returns {Function} A function to unregister this listener
     */
    on(event, callback) {
        if (!this.listeners[event]) {
            this.listeners[event] = [];
        }
        this.listeners[event].push(callback);

        // Return unsubscribe function
        return () => this.off(event, callback);
    }

    /**
     * Register a one-time event listener
     * The listener will be automatically removed after being called once
     * @param {string} event - The event name to listen for
     * @param {Function} callback - The function to call when the event is dispatched
     * @returns {Function} A function to unregister this listener
     */
    once(event, callback) {
        const onceWrapper = (data) => {
            callback(data);
            this.off(event, onceWrapper);
        };
        return this.on(event, onceWrapper);
    }

    /**
     * Unregister an event listener
     * @param {string} event - The event name
     * @param {Function} callback - The callback function to remove
     */
    off(event, callback) {
        if (!this.listeners[event]) {
            return;
        }

        this.listeners[event] = this.listeners[event].filter(
            listener => listener !== callback
        );

        // Clean up empty listener arrays
        if (this.listeners[event].length === 0) {
            delete this.listeners[event];
        }
    }

    /**
     * Dispatch an event to all registered listeners
     * @param {string} event - The event name to dispatch
     * @param {any} data - The data to pass to the listeners
     */
    dispatch(event, data) {
        if (!this.listeners[event]) {
            return;
        }

        // Create a copy of the listeners array to avoid issues if listeners are added/removed during dispatch
        const listeners = [...this.listeners[event]];
        
        listeners.forEach(callback => {
            try {
                callback(data);
            } catch (error) {
                Logger.error(`Error in event listener for "${event}":`, error);
            }
        });
    }

    /**
     * Remove all listeners for a specific event
     * If no event is specified, removes all listeners for all events
     * @param {string} [event] - The event name (optional)
     */
    clear(event) {
        if (event) {
            delete this.listeners[event];
        } else {
            this.listeners = {};
        }
    }

    /**
     * Get the number of listeners for an event
     * @param {string} event - The event name
     * @returns {number} The number of listeners
     */
    listenerCount(event) {
        return this.listeners[event] ? this.listeners[event].length : 0;
    }

    /**
     * Get all event names that have listeners
     * @returns {string[]} Array of event names
     */
    eventNames() {
        return Object.keys(this.listeners);
    }
}

// Create and export the global event bus instance
const eventBus = new EventBus();

// Make it globally available
window.eventBus = eventBus;
window.EventBus = EventBus;

