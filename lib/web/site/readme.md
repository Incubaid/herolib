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

// Access the configured site
mut mysite := site.get(name: 'my_docs')!

// Print available pages
for page_id, page in mysite.pages {
    console.print_item('Page: ${page_id} - "${page.title}"')
}

println('Site has ${mysite.pages.len} pages')
```

---

## API Reference

### Site Factory

Factory functions to create and retrieve site instances:

```v
// Create a new site
mut mysite := site.new(name: 'my_docs')!

// Get existing site
mut mysite := site.get(name: 'my_docs')!

// Check if site exists
if site.exists(name: 'my_docs') {
    println('Site exists')
}

// Get all site names
site_names := site.list()  // Returns []string

// Get default site (creates if needed)
mut default := site.default()!
```

### Site Object Structure

```v
pub struct Site {
pub mut:
    pages      map[string]Page  // key: "collection:page_name"
    nav        NavConfig        // Navigation sidebar
    siteconfig SiteConfig       // Full configuration
}
```

### Accessing Pages

```v
// Access all pages
pages := mysite.pages  // map[string]Page

// Get specific page
page := mysite.pages['docs:introduction']

// Page structure
pub struct Page {
pub mut:
    id          string  // "collection:page_name"
    title       string  // Display title
    description string  // SEO metadata
    draft       bool    // Hidden if true
    hide_title  bool    // Don't show title in rendering
    src         string  // Source reference
}
```

### Navigation Structure

```v
// Access sidebar navigation
sidebar := mysite.nav.my_sidebar  // []NavItem

// NavItem is a sum type (can be one of three types):
pub type NavItem = NavDoc | NavCat | NavLink

// Navigation items:

pub struct NavDoc {
pub:
    id    string  // page id
    label string  // display name
}

pub struct NavCat {
pub mut:
    label       string
    collapsible bool
    collapsed   bool
    items       []NavItem  // nested NavDoc/NavCat/NavLink
}

pub struct NavLink {
pub:
    label       string
    href        string
    description string
}

// Example: iterate navigation
for item in mysite.nav.my_sidebar {
    match item {
        NavDoc {
            println('Page: ${item.label} (${item.id})')
        }
        NavCat {
            println('Category: ${item.label} (${item.items.len} items)')
        }
        NavLink {
            println('Link: ${item.label} -> ${item.href}')
        }
    }
}
```

### Site Configuration

```v
pub struct SiteConfig {
pub mut:
    // Core
    name        string
    title       string
    description string
    tagline     string
    favicon     string
    image       string
    copyright   string

    // URLs (Docusaurus)
    url         string    // Full site URL
    base_url    string    // Base path (e.g., "/" or "/docs/")
    url_home    string    // Home page path

    // SEO Metadata
    meta_title  string    // SEO title override
    meta_image  string    // OG image override

    // Publishing
    build_dest      []BuildDest  // Production destinations
    build_dest_dev  []BuildDest  // Development destinations

    // Navigation & Footer
    footer      Footer
    menu        Menu
    announcement AnnouncementBar
    
    // Imports
    imports     []ImportItem
}

pub struct BuildDest {
pub mut:
    path     string
    ssh_name string
}
```

---

## Core Concepts

### Site
A website configuration that contains pages, navigation structure, and metadata.

### Page
A single page with:
- **ID**: `collection:page_name` format
- **Title**: Display name (optional - extracted from markdown if not provided)
- **Description**: SEO metadata
- **Draft**: Hidden from navigation if true

### Category (Section)
Groups related pages together in the navigation sidebar. Automatically collapsed/expandable.

### Collection
A logical group of pages. Pages reuse the collection once specified.

```heroscript
!!site.page src: "tech:intro"          # Specifies collection "tech"
!!site.page src: "benefits"             # Reuses collection "tech" 
!!site.page src: "components"           # Still uses collection "tech"
!!site.page src: "api:reference"       # Switches to collection "api"
!!site.page src: "endpoints"            # Uses collection "api"
```

---

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
!!site.announcement
    content: "🎉 Version 2.0 is now available!"
    background_color: "#20232a"
    text_color: "#fff"
    is_closeable: true
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

**Category Parameters:**
- `name` - Category identifier (required)
- `label` - Display label (auto-generated from name if omitted)
- `position` - Sort order (auto-incremented if omitted)

### 7. Content Imports

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

## File Organization

### Recommended Ebook Structure

The modern ebook structure uses `.hero` files for configuration and `.heroscript` files for page definitions:

```
my_ebook/
├── scan.hero              # !!atlas.scan - collection scanning
├── config.hero            # !!site.config - site configuration
├── menus.hero             # !!site.navbar and !!site.footer
├── include.hero           # !!docusaurus.define and !!atlas.export
├── 1_intro.heroscript     # Page definitions (categories + pages)
├── 2_concepts.heroscript  # More page definitions
└── 3_advanced.heroscript  # Additional pages
```

### File Types

- **`.hero` files**: Configuration files processed in any order
- **`.heroscript` files**: Page definition files processed alphabetically

Use numeric prefixes on `.heroscript` files to control page/category ordering in the sidebar.

### Example scan.hero

```heroscript
!!atlas.scan path:"../../collections/my_collection"
```

### Example include.hero

```heroscript
// Include shared configuration (optional)
!!play.include path:'../../heroscriptall' replace:'SITENAME:my_ebook'

// Or define directly
!!docusaurus.define name:'my_ebook'

!!atlas.export include:true
```

### Running an Ebook

```bash
# Development server
hero docs -d -p /path/to/my_ebook

# Build for production
hero docs -p /path/to/my_ebook
```

