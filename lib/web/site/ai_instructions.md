# AI Instructions for Site Module HeroScript

This document provides comprehensive instructions for AI agents working with the Site module's HeroScript format.

## HeroScript Format Overview

HeroScript is a declarative configuration language with the following characteristics:

### Basic Syntax

```heroscript
!!actor.action
    param1: "value1"
    param2: "value2"
    multiline_param: "
        This is a multiline value.
        It can span multiple lines.
    "
    arg1 arg2  // Arguments without keys
```

**Key Rules:**
1. Actions start with `!!` followed by `actor.action` format
2. Parameters are indented and use `key: "value"` or `key: value` format
3. Values with spaces must be quoted
4. Multiline values are supported with quotes
5. Arguments without keys are space-separated
6. Comments start with `//`

## Site Module Actions

### 1. Site Configuration (`!!site.config`)

**Purpose:** Define the main site configuration including title, description, and metadata.

**Required Parameters:**
- `name`: Site identifier (will be normalized to snake_case)

**Optional Parameters:**
- `title`: Site title (default: "Documentation Site")
- `description`: Site description
- `tagline`: Site tagline
- `favicon`: Path to favicon (default: "img/favicon.png")
- `image`: Default site image (default: "img/tf_graph.png")
- `copyright`: Copyright text
- `url`: Main site URL
- `base_url`: Base URL path (default: "/")
- `url_home`: Home page path

**Example:**
```heroscript
!!site.config
    name: "my_documentation"
    title: "My Documentation Site"
    description: "Comprehensive technical documentation"
    tagline: "Learn everything you need"
    url: "https://docs.example.com"
    base_url: "/"
```

**AI Guidelines:**
- Always include `name` parameter
- Use descriptive titles and descriptions
- Ensure URLs are properly formatted with protocol

### 2. Metadata Configuration (`!!site.config_meta`)

**Purpose:** Override specific metadata for SEO purposes.

**Optional Parameters:**
- `title`: SEO-specific title (overrides site.config title for meta tags)
- `image`: SEO-specific image (overrides site.config image for og:image)
- `description`: SEO-specific description

**Example:**
```heroscript
!!site.config_meta
    title: "My Docs - Complete Guide"
    image: "img/social-preview.png"
    description: "The ultimate guide to using our platform"
```

**AI Guidelines:**
- Use only when SEO metadata needs to differ from main config
- Keep titles concise for social media sharing
- Use high-quality images for social previews

### 3. Navigation Bar (`!!site.navbar` or `!!site.menu`)

**Purpose:** Configure the main navigation bar.

**Optional Parameters:**
- `title`: Navigation title (defaults to site.config title)
- `logo_alt`: Logo alt text
- `logo_src`: Logo image path
- `logo_src_dark`: Dark mode logo path

**Example:**
```heroscript
!!site.navbar
    title: "My Site"
    logo_alt: "My Site Logo"
    logo_src: "img/logo.svg"
    logo_src_dark: "img/logo-dark.svg"
```

**AI Guidelines:**
- Use `!!site.navbar` for modern syntax (preferred)
- `!!site.menu` is supported for backward compatibility
- Provide both light and dark logos when possible

### 4. Navigation Items (`!!site.navbar_item` or `!!site.menu_item`)

**Purpose:** Add items to the navigation bar.

**Required Parameters (one of):**
- `to`: Internal link path
- `href`: External URL

**Optional Parameters:**
- `label`: Display text (required in practice)
- `position`: "left" or "right" (default: "right")

**Example:**
```heroscript
!!site.navbar_item
    label: "Documentation"
    to: "docs/intro"
    position: "left"

!!site.navbar_item
    label: "GitHub"
    href: "https://github.com/myorg/repo"
    position: "right"
```

**AI Guidelines:**
- Use `to` for internal navigation
- Use `href` for external links
- Position important items on the left, secondary items on the right

### 5. Footer Configuration (`!!site.footer`)

**Purpose:** Configure footer styling.

**Optional Parameters:**
- `style`: "dark" or "light" (default: "dark")

**Example:**
```heroscript
!!site.footer
    style: "dark"
```

### 6. Footer Items (`!!site.footer_item`)

**Purpose:** Add links to the footer, grouped by title.

**Required Parameters:**
- `title`: Group title (items with same title are grouped together)
- `label`: Link text

**Required Parameters (one of):**
- `to`: Internal link path
- `href`: External URL

**Example:**
```heroscript
!!site.footer_item
    title: "Docs"
    label: "Introduction"
    to: "intro"

!!site.footer_item
    title: "Docs"
    label: "API Reference"
    to: "api"

!!site.footer_item
    title: "Community"
    label: "Discord"
    href: "https://discord.gg/example"
```

**AI Guidelines:**
- Group related links under the same title
- Use consistent title names across related items
- Provide both internal and external links as appropriate

### 7. Page Categories (`!!site.page_category`)

**Purpose:** Create a section/category to organize pages.

**Required Parameters:**
- `name`: Category identifier (snake_case)

**Optional Parameters:**
- `label`: Display name (auto-generated from name if not provided)
- `position`: Manual sort order (auto-incremented if not specified)
- `path`: URL path segment (defaults to normalized label)

**Example:**
```heroscript
!!site.page_category
    name: "getting_started"
    label: "Getting Started"
    position: 100

!!site.page_category
    name: "advanced_topics"
    label: "Advanced Topics"
```

**AI Guidelines:**
- Use descriptive snake_case names
- Let label be auto-generated when possible (name_fix converts to Title Case)
- Categories persist for all subsequent pages until a new category is declared
- Position values should leave gaps (100, 200, 300) for future insertions

### 8. Pages (`!!site.page`)

**Purpose:** Define individual pages in the site.

**Required Parameters:**
- `src`: Source reference as `collection:page_name` (required for first page in a collection)

**Optional Parameters:**
- `name`: Page identifier (extracted from src if not provided)
- `title`: Page title (extracted from markdown if not provided)
- `description`: Page description for metadata
- `slug`: Custom URL slug
- `position`: Manual sort order (auto-incremented if not specified)
- `draft`: Mark as draft (default: false)
- `hide_title`: Hide title in rendering (default: false)
- `path`: Custom path (defaults to current category name)
- `category`: Override current category
- `title_nr`: Title numbering level

**Example:**
```heroscript
!!site.page src: "docs:introduction"
    description: "Introduction to the platform"
    slug: "/"

!!site.page src: "quickstart"
    description: "Get started in 5 minutes"

!!site.page src: "installation"
    title: "Installation Guide"
    description: "How to install and configure"
    position: 10
```

**AI Guidelines:**
- **Collection Persistence:** Specify collection once (e.g., `docs:introduction`), then subsequent pages only need page name (e.g., `quickstart`)
- **Category Persistence:** Pages belong to the most recently declared category
- **Title Extraction:** Prefer extracting titles from markdown files
- **Position Management:** Use automatic positioning unless specific order is required
- **Description Required:** Always provide descriptions for SEO
- **Slug Usage:** Use slug for special pages like homepage (`slug: "/"`)

### 9. Import External Content (`!!site.import`)

**Purpose:** Import content from external sources.

**Optional Parameters:**
- `name`: Import identifier
- `url`: Git URL or HTTP URL
- `path`: Local file system path
- `dest`: Destination path in site
- `replace`: Comma-separated key:value pairs for variable replacement
- `visible`: Whether imported content is visible (default: true)

**Example:**
```heroscript
!!site.import
    url: "https://github.com/example/docs"
    dest: "external"
    replace: "VERSION:1.0.0,PROJECT:MyProject"
    visible: true
```

**AI Guidelines:**
- Use for shared documentation across multiple sites
- Replace variables using `${VARIABLE}` syntax in source content
- Set `visible: false` for imported templates or partials

### 10. Publish Destinations (`!!site.publish` and `!!site.publish_dev`)

**Purpose:** Define where to publish the built site.

**Optional Parameters:**
- `path`: File system path or URL
- `ssh_name`: SSH connection name for remote deployment

**Example:**
```heroscript
!!site.publish
    path: "/var/www/html/docs"
    ssh_name: "production_server"

!!site.publish_dev
    path: "/tmp/docs-preview"
```

**AI Guidelines:**
- Use `!!site.publish` for production deployments
- Use `!!site.publish_dev` for development/preview deployments
- Can specify multiple destinations

## File Organization Best Practices

### Naming Convention

Use numeric prefixes to control execution order:

```
0_config.heroscript       # Site configuration
1_navigation.heroscript   # Menu and footer
2_intro.heroscript        # Introduction pages
3_guides.heroscript       # User guides
4_reference.heroscript    # API reference
```

**AI Guidelines:**
- Always use numeric prefixes (0_, 1_, 2_, etc.)
- Leave gaps in numbering (0, 10, 20) for future insertions
- Group related configurations in the same file
- Process order matters: config → navigation → pages

### Execution Order Rules

1. **Configuration First:** `!!site.config` must be processed before other actions
2. **Categories Before Pages:** Declare `!!site.page_category` before pages in that category
3. **Collection Persistence:** First page in a collection must specify `collection:page_name`
4. **Category Persistence:** Pages inherit the most recent category declaration

## Common Patterns

### Pattern 1: Simple Documentation Site

```heroscript
!!site.config
    name: "simple_docs"
    title: "Simple Documentation"

!!site.navbar
    title: "Simple Docs"

!!site.page src: "docs:index"
    description: "Welcome page"
    slug: "/"

!!site.page src: "getting-started"
    description: "Getting started guide"

!!site.page src: "api"
    description: "API reference"
```

### Pattern 2: Multi-Section Documentation

```heroscript
!!site.config
    name: "multi_section_docs"
    title: "Complete Documentation"

!!site.page_category
    name: "introduction"
    label: "Introduction"

!!site.page src: "docs:welcome"
    description: "Welcome to our documentation"

!!site.page src: "overview"
    description: "Platform overview"

!!site.page_category
    name: "tutorials"
    label: "Tutorials"

!!site.page src: "tutorial_basics"
    description: "Basic tutorial"

!!site.page src: "tutorial_advanced"
    description: "Advanced tutorial"
```

### Pattern 3: Complex Site with External Links

```heroscript
!!site.config
    name: "complex_site"
    title: "Complex Documentation Site"
    url: "https://docs.example.com"

!!site.navbar
    title: "My Platform"
    logo_src: "img/logo.svg"

!!site.navbar_item
    label: "Docs"
    to: "docs/intro"
    position: "left"

!!site.navbar_item
    label: "API"
    to: "api"
    position: "left"

!!site.navbar_item
    label: "GitHub"
    href: "https://github.com/example/repo"
    position: "right"

!!site.footer
    style: "dark"

!!site.footer_item
    title: "Documentation"
    label: "Getting Started"
    to: "docs/intro"

!!site.footer_item
    title: "Community"
    label: "Discord"
    href: "https://discord.gg/example"

!!site.page_category
    name: "getting_started"

!!site.page src: "docs:introduction"
    description: "Introduction to the platform"
    slug: "/"

!!site.page src: "installation"
    description: "Installation guide"
```

## Error Prevention

### Common Mistakes to Avoid

1. **Missing Collection on First Page:**
   ```heroscript
   # WRONG - no collection specified
   !!site.page src: "introduction"
   
   # CORRECT
   !!site.page src: "docs:introduction"
   ```

2. **Category Without Name:**
   ```heroscript
   # WRONG - missing name
   !!site.page_category
       label: "Getting Started"
   
   # CORRECT
   !!site.page_category
       name: "getting_started"
       label: "Getting Started"
   ```

3. **Missing Description:**
   ```heroscript
   # WRONG - no description
   !!site.page src: "docs:intro"
   
   # CORRECT
   !!site.page src: "docs:intro"
       description: "Introduction to the platform"
   ```

4. **Incorrect File Ordering:**
   ```
   # WRONG - pages before config
   pages.heroscript
   config.heroscript
   
   # CORRECT - config first
   0_config.heroscript
   1_pages.heroscript
   ```

## Validation Checklist

When generating HeroScript for the Site module, verify:

- [ ] `!!site.config` includes `name` parameter
- [ ] All pages have `description` parameter
- [ ] First page in each collection specifies `collection:page_name`
- [ ] Categories are declared before their pages
- [ ] Files use numeric prefixes for ordering
- [ ] Navigation items have either `to` or `href`
- [ ] Footer items are grouped by `title`
- [ ] External URLs include protocol (https://)
- [ ] Paths don't have trailing slashes unless intentional
- [ ] Draft pages are marked with `draft: true`

## Integration with V Code

When working with the Site module in V code:

```v
import incubaid.herolib.web.site
import incubaid.herolib.core.playbook

// Process HeroScript files
mut plbook := playbook.new(path: '/path/to/heroscripts')!
site.play(mut plbook)!

// Access configured site
mut mysite := site.get(name: 'my_site')!

// Iterate through pages
for page in mysite.pages {
    println('Page: ${page.name} - ${page.description}')
}

// Iterate through sections
for section in mysite.sections {
    println('Section: ${section.label}')
}
```

## Summary

The Site module's HeroScript format provides a declarative way to configure websites with:
- Clear separation of concerns (config, navigation, content)
- Automatic ordering and organization
- Collection and category persistence for reduced repetition
- Flexible metadata and SEO configuration
- Support for both internal and external content

Always follow the execution order rules, use numeric file prefixes, and provide complete metadata for best results.