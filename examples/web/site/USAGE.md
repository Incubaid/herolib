# Site Module Usage Guide

## Quick Examples

### 1. Run Basic Example

```bash
cd examples/web/site
vrun process_site.vsh ./
```

With output:
```
=== Site Configuration Processor ===
Processing HeroScript files from: ./
Found 1 HeroScript file(s):
  - basic.heroscript

Processing: basic.heroscript

=== Configuration Complete ===
Site: simple_docs
Title: Simple Documentation
Pages: 4
Description: A basic documentation site
Navigation structure:
  - [Page] Getting Started
  - [Page] Installation
  - [Page] Usage Guide
  - [Page] FAQ

✓ Site configuration ready for deployment
```

### 2. Run Multi-Section Example

```bash
vrun process_site.vsh ./
# Edit process_site.vsh to use multi_section.heroscript instead
```

### 3. Process Custom Directory

```bash
vrun process_site.vsh /path/to/your/site/config
```

## File Structure

```
docs/
├── 0_config.heroscript     # Basic config
├── 1_menu.heroscript       # Navigation
├── 2_pages.heroscript      # Pages and categories
└── process.vsh             # Your processing script
```

## Creating Your Own Site

1. **Create a config directory:**
   ```bash
   mkdir my_site
   cd my_site
   ```

2. **Create config file (0_config.heroscript):**
   ```heroscript
   !!site.config
       name: "my_site"
       title: "My Site"
   ```

3. **Create pages file (1_pages.heroscript):**
   ```heroscript
   !!site.page src: "docs:intro"
       title: "Getting Started"
   ```

4. **Process with script:**
   ```bash
   vrun ../process_site.vsh ./
   ```

## Common Workflows

### Workflow 1: Documentation Site

```
docs/
├── 0_config.heroscript
│   └── Basic config + metadata
├── 1_menu.heroscript
│   └── Navbar + footer
├── 2_getting_started.heroscript
│   └── Getting started pages
├── 3_api.heroscript
│   └── API reference pages
└── 4_advanced.heroscript
    └── Advanced topic pages
```

### Workflow 2: Internal Knowledge Base

```
kb/
├── 0_config.heroscript
├── 1_navigation.heroscript
└── 2_articles.heroscript
```

### Workflow 3: Product Documentation with Imports

```
product_docs/
├── 0_config.heroscript
├── 1_imports.heroscript
│   └── Import shared templates
├── 2_menu.heroscript
└── 3_pages.heroscript
```

## Tips & Tricks

### Tip 1: Reuse Collections

```heroscript
# Specify once, reuse multiple times
!!site.page src: "guides:intro"
!!site.page src: "setup"        # Reuses "guides"
!!site.page src: "deployment"   # Still "guides"

# Switch to new collection
!!site.page src: "api:reference"
!!site.page src: "examples"     # Now "api"
```

### Tip 2: Auto-Increment Categories

```heroscript
# Automatically positioned at 100, 200, 300...
!!site.page_category name: "basics"
!!site.page_category name: "advanced"
!!site.page_category name: "expert"

# Or specify explicit positions
!!site.page_category name: "basics" position: 10
!!site.page_category name: "advanced" position: 20
```

### Tip 3: Title Extraction

Let titles come from markdown files:

```heroscript
# Don't specify title
!!site.page src: "docs:introduction"
# Title will be extracted from # Heading in introduction.md
```

### Tip 4: Draft Pages

Hide pages while working on them:

```heroscript
!!site.page src: "docs:work_in_progress"
    draft: true
    title: "Work in Progress"
```

## Debugging

### Debug: Check What Got Configured

```v
mut s := site.get(name: 'my_site')!
println(s.pages)        // All pages
println(s.nav)          // Navigation structure
println(s.siteconfig)   // Configuration
```

### Debug: List All Sites

```v
sites := site.list()
for site_name in sites {
    println('Site: ${site_name}')
}
```

### Debug: Enable Verbose Output

Add `console.print_debug()` calls in your HeroScript processing.

## Next Steps

- Customize `process_site.vsh` for your needs
- Add your existing pages (in markdown)
- Export to Docusaurus
- Deploy to production

For more info, see the main [Site Module README](./readme.md).