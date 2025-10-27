/**
 * Macro Parser and Processor
 * Parses HeroScript-style macros from markdown content
 */

class MacroParser {
    /**
     * Parse and extract all macros from content
     * Returns array of { fullMatch, actor, method, params }
     */
    static extractMacros(content) {
        const macroRegex = /!!([\w.]+)\s*([\s\S]*?)(?=\n!!|\n#|$)/g;
        const macros = [];
        let match;
        
        while ((match = macroRegex.exec(content)) !== null) {
            const fullMatch = match[0];
            const actionPart = match[1]; // e.g., "include" or "core.include"
            const paramsPart = match[2];
            
            // Parse action: "method" or "actor.method"
            const [actor, method] = actionPart.includes('.')
                ? actionPart.split('.')
                : ['core', actionPart];
            
            // Parse parameters from HeroScript-like syntax
            const params = this.parseParams(paramsPart);
            
            macros.push({
                fullMatch: fullMatch.trim(),
                actor,
                method,
                params,
                start: match.index,
                end: match.index + fullMatch.length
            });
        }
        
        return macros;
    }
    
    /**
     * Parse HeroScript-style parameters
     * key: value
     * key: 'value with spaces'
     * key: |
     *   multiline
     *   value
     */
    static parseParams(paramsPart) {
        const params = {};
        
        if (!paramsPart || !paramsPart.trim()) {
            return params;
        }
        
        // Split by newlines but preserve multiline values
        const lines = paramsPart.split('\n');
        let currentKey = null;
        let currentValue = [];
        
        for (const line of lines) {
            const trimmed = line.trim();
            
            if (!trimmed) continue;
            
            // Check if this is a key: value line
            if (trimmed.includes(':')) {
                // Save previous key-value
                if (currentKey) {
                    params[currentKey] = currentValue.join('\n').trim();
                }
                
                const [key, ...valueParts] = trimmed.split(':');
                currentKey = key.trim();
                currentValue = [valueParts.join(':').trim()];
            } else if (currentKey) {
                // Continuation of multiline value
                currentValue.push(trimmed);
            }
        }
        
        // Save last key-value
        if (currentKey) {
            params[currentKey] = currentValue.join('\n').trim();
        }
        
        return params;
    }
    
    /**
     * Check if macro is valid
     */
    static validateMacro(macro) {
        if (!macro.actor || !macro.method) {
            return { valid: false, error: 'Invalid macro format' };
        }
        
        return { valid: true };
    }
}

window.MacroParser = MacroParser;