# Site Module

The Site module provides a structured way to define website configurations, navigation menus, pages, and sections using HeroScript. It's designed to work with static site generators like Docusaurus.

## Purpose

The Site module allows you to:
- Define website structure and configuration in a declarative way using HeroScript
- Organize pages into sections/categories
- Configure navigation menus and footers
- Manage page metadata (title, description, slug, etc.)
- Support multiple content collections
- Define build and publish destinations

## Quick Start

```v
#!/usr/bin/env -S v -n -w -gc none -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.develop.gittools
import incubaid.herolib.web.site
import incubaid.herolib.core.playcmds

// Clone or use existing repository with HeroScript files
mysitepath := gittools.path(
    git_url: 'https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/ebooks/tech'
    git_pull: true
)!

// Process all HeroScript files in the path
playcmds.run(heroscript_path: mysitepath.path)!

// Get the configured site
mut mysite := site.get(name: 'tfgrid_tech')!
println(mysite)
```

## HeroScript Syntax

### Basic Configuration

```heroscript
!!site.config
    name: "my_site"
    title: "My Documentation Site"
    description: "Comprehensive documentation"
    tagline: "Your awesome documentation"
    favicon: "img/favicon.png"
    image: "img/site-image.png"
    copyright: "© 2024 My Organization"
    url: "https://docs.example.com"
    base_url: "/"
```

### Navigation Menu

```heroscript
!!site.navbar
    title: "My Site"
    logo_alt: "Site Logo"
    logo_src: "img/logo.svg"
    logo_src_dark: "img/logo-dark.svg"

!!site.navbar_item
    label: "Documentation"
    to: "docs/intro"
    position: "left"

!!site.navbar_item
    label: "GitHub"
    href: "https://github.com/myorg/myrepo"
    position: "right"
```

### Footer Configuration

```heroscript
!!site.footer
    style: "dark"

!!site.footer_item
    title: "Docs"
    label: "Introduction"
    to: "intro"

!!site.footer_item
    title: "Docs"
    label: "Getting Started"
    href: "https://docs.example.com/getting-started"

!!site.footer_item
    title: "Community"
    label: "Discord"
    href: "https://discord.gg/example"
```

## Page Organization

### Example 1: Simple Pages Without Categories

When you don't need categories, pages are added sequentially. The collection only needs to be specified once, then it's reused for subsequent pages.

```heroscript
!!site.page src: "tech:introduction"
    description: "Introduction to ThreeFold Technology"
    slug: "/"

!!site.page src: "vision"
    description: "Our Vision for the Future Internet"

!!site.page src: "what"
    description: "What ThreeFold is Building"

!!site.page src: "presentation"
    description: "ThreeFold Technology Presentation"

!!site.page src: "status"
    description: "Current Development Status"
```

**Key Points:**
- First page specifies collection as `tech:introduction` (collection:page_name format)
- Subsequent pages only need the page name (e.g., `vision`) - the `tech` collection is reused
- If `title` is not specified, it will be extracted from the markdown file itself
- Pages are ordered by their appearance in the HeroScript file
- `slug` can be used to customize the URL path (e.g., `"/"` for homepage)

### Example 2: Pages with Categories

Categories (sections) help organize pages into logical groups with their own navigation structure.

```heroscript
!!site.page_category
    name: "first_principle_thinking"
    label: "First Principle Thinking"

!!site.page src: "first_principle_thinking:hardware_badly_used"
    description: "Hardware is not used properly, why it is important to understand hardware"

!!site.page src: "internet_risk"
    description: "Internet risk, how to mitigate it, and why it is important"

!!site.page src: "onion_analogy"
    description: "Compare onion with a computer, layers of abstraction"
```

**Key Points:**
- `!!site.page_category` creates a new section/category
- `name` is the internal identifier (snake_case)
- `label` is the display name (automatically derived from `name` if not specified)
- Category name is converted to title case: `first_principle_thinking` → "First Principle Thinking"
- Once a category is defined, all subsequent pages belong to it until a new category is declared
- Collection persistence works the same: specify once (e.g., `first_principle_thinking:hardware_badly_used`), then reuse

### Example 3: Advanced Page Configuration

```heroscript
!!site.page_category
    name: "components"
    label: "System Components"
    position: 100

!!site.page src: "tech:mycelium"
    title: "Mycelium Network"
    description: "Peer-to-peer overlay network"
    slug: "mycelium-network"
    position: 1
    draft: false
    hide_title: false

!!site.page src: "fungistor"
    title: "Fungistor Storage"
    description: "Distributed storage system"
    position: 2
```

**Available Page Parameters:**
- `src`: Source reference as `collection:page_name` (required for first page in collection)
- `title`: Page title (optional, extracted from markdown if not provided)
- `description`: Page description for metadata
- `slug`: Custom URL slug
- `position`: Manual ordering (auto-incremented if not specified)
- `draft`: Mark page as draft (default: false)
- `hide_title`: Hide the page title in rendering (default: false)
- `path`: Custom path for the page (defaults to category name)
- `category`: Override the current category for this page

## File Organization

HeroScript files should be organized with numeric prefixes to control execution order:

```
docs/
├── 0_config.heroscript       # Site configuration
├── 1_menu.heroscript          # Navigation and footer
├── 2_intro_pages.heroscript   # Introduction pages
├── 3_tech_pages.heroscript    # Technical documentation
└── 4_api_pages.heroscript     # API reference
```

**Important:** Files are processed in alphabetical order, so use numeric prefixes (0_, 1_, 2_, etc.) to ensure correct execution sequence.

## Import External Content

```heroscript
!!site.import
    url: "https://github.com/example/external-docs"
    dest: "external"
    replace: "PROJECT_NAME:My Project,VERSION:1.0.0"
    visible: true
```

## Publish Destinations

```heroscript
!!site.publish
    path: "/var/www/html/docs"
    ssh_name: "production_server"

!!site.publish_dev
    path: "/tmp/docs-preview"
```

## Factory Methods

### Create or Get a Site

```v
import incubaid.herolib.web.site

// Create a new site
mut mysite := site.new(name: 'my_docs')!

// Get an existing site
mut mysite := site.get(name: 'my_docs')!

// Get default site
mut mysite := site.default()!

// Check if site exists
if site.exists(name: 'my_docs') {
    println('Site exists')
}

// List all sites
sites := site.list()
println(sites)
```

### Using with PlayBook

```v
import incubaid.herolib.core.playbook
import incubaid.herolib.web.site

// Create playbook from path
mut plbook := playbook.new(path: '/path/to/heroscripts')!

// Process site configuration
site.play(mut plbook)!

// Access the configured site
mut mysite := site.get(name: 'my_site')!
```

## Data Structures

### Site

```v
pub struct Site {
pub mut:
    pages      []Page
    sections   []Section
    siteconfig SiteConfig
}
```

### Page

```v
pub struct Page {
pub mut:
    name         string  // Page identifier
    title        string  // Display title
    description  string  // Page description
    draft        bool    // Draft status
    position     int     // Sort order
    hide_title   bool    // Hide title in rendering
    src          string  // Source as collection:page_name
    path         string  // URL path (without page name)
    section_name string  // Category/section name
    title_nr     int     // Title numbering level
    slug         string  // Custom URL slug
}
```

### Section

```v
pub struct Section {
pub mut:
    name     string  // Internal identifier
    position int     // Sort order
    path     string  // URL path
    label    string  // Display name
}
```

## Best Practices

1. **File Naming**: Use numeric prefixes (0_, 1_, 2_) to control execution order
2. **Collection Reuse**: Specify collection once, then reuse for subsequent pages
3. **Category Organization**: Group related pages under categories for better navigation
4. **Title Extraction**: Let titles be extracted from markdown files when possible
5. **Position Management**: Use automatic positioning unless you need specific ordering
6. **Description**: Always provide descriptions for better SEO and navigation
7. **Draft Status**: Use `draft: true` for work-in-progress pages

## Complete Example

See `examples/web/site/site_example.vsh` for a complete working example.

For a real-world example, check: https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/ebooks/tech