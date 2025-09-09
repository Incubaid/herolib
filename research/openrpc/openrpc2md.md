

# Instructions: Converting OpenRPC → Markdown Shorthand

## Purpose

Transform an OpenRPC specification (JSON or YAML) into a **dense Markdown format** that is:

* Human-readable
* AI-parseable
* Compact (minimal boilerplate)
* Faithful to the original semantics

---

## General Rules

1. **Drop metadata**
   Ignore `info`, `servers`, and other metadata not relevant to API usage.

2. **Two main sections**

   * `# Methods`
   * `# Schemas`

3. **Method representation**
   Each method gets its own `## {method_name}` block:

   * First line: *description* (if present).
   * **Params** section:

     * List each parameter as `- name: TYPE (required?)`
     * Inline object properties using nested bullet lists or YAML block if complex.
   * **Result** section:

     * Same style as params.
     * Use shorthand for references:

       * `$ref: "#/components/schemas/Comment"` → `Comment`
       * Array of refs → `[Comment]`

4. **Schema representation**
   Each schema gets its own `## {SchemaName}` block:

   * Use fenced YAML block for properties:

     ```yaml
     field: TYPE   # description
     ```
   * List required fields below the block:
     `*Required: field1, field2*`

---

## Type Conventions

* `type: integer` → `int`
* `type: string` → `str`
* `type: boolean` → `bool`
* `type: object` → `object`
* `type: array` → `[TYPE]` (if items defined)
* `oneOf: [SchemaA, SchemaB]` → `SchemaA | SchemaB`

---

## Handling Complex Types

1. **Objects inside parameters or results**

   * If small (≤3 fields), inline as `{ field1: TYPE, field2: TYPE }`.
   * If large, expand as YAML block.

   Example:

   ```markdown
   - args (object, required)
     - id: int
     - parent: int
   ```

2. **Nested schemas (structs in structs)**

   * Inline only the top level, reference nested schemas by name.
   * If the nested schema is not declared in `components/schemas`, define it under `# Schemas`.

   Example:

   ```markdown
   ## user_create
   **Params**
   - user: UserProfile  (struct defined below)
   ```

3. **Arrays**

   * `[TYPE]` for primitives (e.g., `[int]`).
   * `[SchemaName]` for objects.

4. **Results with multiple options**

   * Use `SchemaA | [SchemaA]` for "oneOf".

---

## Example Conversion

OpenRPC (fragment):

```json
{
  "name": "comment_get",
  "description": "Retrieve comments",
  "params": [
    {
      "name": "args",
      "required": true,
      "schema": {
        "type": "object",
        "properties": {
          "id": { "type": "integer" },
          "author": { "type": "integer" }
        }
      }
    }
  ],
  "result": {
    "name": "comments",
    "schema": {
      "oneOf": [
        { "$ref": "#/components/schemas/Comment" },
        { "type": "array", "items": { "$ref": "#/components/schemas/Comment" } }
      ]
    }
  }
}
```

Markdown:

```markdown
## comment_get
Retrieve comments

**Params**
- args (object, required)  
  - id: int  
  - author: int  

**Result**
- comments: Comment | [Comment]
```

---

This way, any AI (or human) can deterministically map **OpenRPC → Markdown shorthand**.
