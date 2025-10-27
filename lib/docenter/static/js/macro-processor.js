/**
 * Macro Processor
 * Handles macro execution and result rendering
 */

class MacroProcessor {
    constructor(webdavClient) {
        this.webdavClient = webdavClient;
        this.plugins = new Map();
        this.includeStack = []; // Track includes to detect cycles
        this.registerDefaultPlugins();
    }

    /**
     * Register a macro plugin
     * Plugin must implement: { canHandle(actor, method), process(macro, webdavClient) }
     */
    registerPlugin(actor, method, plugin) {
        const key = `${actor}.${method}`;
        this.plugins.set(key, plugin);
    }

    /**
     * Process all macros in content
     * Returns { success: boolean, content: string, errors: [] }
     */
    async processMacros(content) {
        const macros = MacroParser.extractMacros(content);
        const errors = [];
        let processedContent = content;

        // Process macros in reverse order to preserve positions
        for (let i = macros.length - 1; i >= 0; i--) {
            const macro = macros[i];

            try {
                const result = await this.processMacro(macro);

                if (result.success) {
                    // Replace macro with result
                    processedContent =
                        processedContent.substring(0, macro.start) +
                        result.content +
                        processedContent.substring(macro.end);
                } else {
                    errors.push({
                        macro: macro.fullMatch,
                        error: result.error
                    });

                    // Replace with error message
                    const errorMsg = `\n\n⚠️ **Macro Error**: ${result.error}\n\n`;
                    processedContent =
                        processedContent.substring(0, macro.start) +
                        errorMsg +
                        processedContent.substring(macro.end);
                }
            } catch (error) {
                errors.push({
                    macro: macro.fullMatch,
                    error: error.message
                });

                const errorMsg = `\n\n⚠️ **Macro Error**: ${error.message}\n\n`;
                processedContent =
                    processedContent.substring(0, macro.start) +
                    errorMsg +
                    processedContent.substring(macro.end);
            }
        }

        return {
            success: errors.length === 0,
            content: processedContent,
            errors
        };
    }

    /**
     * Process single macro
     */
    async processMacro(macro) {
        const key = `${macro.actor}.${macro.method}`;
        const plugin = this.plugins.get(key);

        // Check for circular includes
        if (macro.method === 'include') {
            const path = macro.params.path || macro.params[''];
            if (this.includeStack.includes(path)) {
                return {
                    success: false,
                    error: `Circular include detected: ${this.includeStack.join(' → ')} → ${path}`
                };
            }
        }

        if (!plugin) {
            return {
                success: false,
                error: `Unknown macro: !!${key}`
            };
        }

        // Validate macro
        const validation = MacroParser.validateMacro(macro);
        if (!validation.valid) {
            return { success: false, error: validation.error };
        }

        // Execute plugin
        try {
            return await plugin.process(macro, this.webdavClient);
        } catch (error) {
            return {
                success: false,
                error: `Plugin error: ${error.message}`
            };
        }
    }

    /**
     * Register default plugins
     */
    registerDefaultPlugins() {
        // Include plugin
        this.registerPlugin('core', 'include', {
            process: async (macro, webdavClient) => {
                const path = macro.params.path || macro.params[''];

                if (!path) {
                    return {
                        success: false,
                        error: 'include macro requires "path" parameter'
                    };
                }

                try {
                    // Add to include stack
                    this.includeStack.push(path);
                    const content = await webdavClient.includeFile(path);
                    // Remove from include stack
                    this.includeStack.pop();
                    return { success: true, content };
                } catch (error) {
                    // Remove from include stack on error
                    this.includeStack.pop();
                    return {
                        success: false,
                        error: `Failed to include "${path}": ${error.message}`
                    };
                }
            }
        });
    }
}

window.MacroProcessor = MacroProcessor;