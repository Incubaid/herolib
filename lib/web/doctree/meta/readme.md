# Site Module

The Site module provides a structured way to define website configurations, navigation menus, pages, and sections using HeroScript. It's designed to work with static site generators like Docusaurus.

## Quick Start

### Minimal HeroScript Example

```heroscript
!!site.config
    name: "my_docs"
    title: "My Documentation"

!!site.page src: "docs:introduction"
    label: "Getting Started"
    title: "Getting Started"

!!site.page src: "setup"
    label: "Installation"
    title: "Installation"
```

### Processing with V Code

```v
import incubaid.herolib.core.playbook
import incubaid.herolib.web.doctree.meta as site_module
import incubaid.herolib.ui.console

// Process HeroScript file
mut plbook := playbook.new(path: './site_config.heroscript')!

// Execute site configuration
site_module.play(mut plbook)!

// Access the configured site
mut mysite := site_module.get(name: 'my_docs')!

// Print available pages
for page in mysite.pages {
    console.print_item('Page: "${page.src}" - "${page.title}"')
}

println('Site has ${mysite.pages.len} pages')
```

---

## API Reference

### Site Factory

Factory functions to create and retrieve site instances:

```v
// Create a new site
mut mysite := site_module.new(name: 'my_docs')!

// Get existing site
mut mysite := site_module.get(name: 'my_docs')!

// Check if site exists
if site_module.exists(name: 'my_docs') {
    println('Site exists')
}

// Get all site names
site_names := site_module.list()  // Returns []string

// Get default site (creates if needed)
mut default := site_module.default()!
```

### Site Object Structure

```v
@[heap]
pub struct Site {
pub mut:
    doctree_path   string       // path to the export of the doctree site
    config         SiteConfig   // Full site configuration	
    pages          []Page       // Array of pages
    links          []Link       // Array of links
    categories     []Category   // Array of categories
    announcements  []Announcement // Array of announcements (can be multiple)
    imports        []ImportItem // Array of imports
    build_dest     []BuildDest  // Production build destinations
    build_dest_dev []BuildDest  // Development build destinations
}
```

### Accessing Pages

```v
// Access all pages
pages := mysite.pages  // []Page

// Access specific page by index
page := mysite.pages[0]

// Page structure
pub struct Page {
pub mut:
    src         string  // "collection:page_name" format (unique identifier)
    label       string  // Display label in navigation
    title       string  // Display title on page (extracted from markdown if empty)
    description string  // SEO metadata
    draft       bool    // Hide from navigation if true
    hide_title  bool    // Don't show title on page
    hide        bool    // Hide page completely
    category_id int     // Optional category ID (0 = root level)
}
```

### Categories and Navigation

```v
// Access all categories
categories := mysite.categories  // []Category

// Category structure
pub struct Category {
pub mut:
    path        string  // e.g., "Getting Started" or "Operations/Daily"
    collapsible bool = true
    collapsed   bool
}

// Generate sidebar navigation
sidebar := mysite.sidebar()  // Returns SideBar

// Sidebar structure
pub struct SideBar {
pub mut:
    my_sidebar []NavItem
}

pub type NavItem = NavDoc | NavCat | NavLink

pub struct NavDoc {
pub:
    path  string  // path is $collection/$name without .md
    label string
}

pub struct NavCat {
pub mut:
    label       string
    collapsible bool = true
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
sidebar := mysite.sidebar()
for item in sidebar.my_sidebar {
    match item {
        NavDoc {
            println('Page: ${item.label} (${item.path})')
        }
        NavCat {
            println('Category: ${item.label} (${item.items.len} items)')
        }
        NavLink {
            println('Link: ${item.label} -> ${item.href}')
        }
    }
}

// Print formatted sidebar
println(mysite.sidebar_str())
```

### Site Configuration

```v
@[heap]
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

    // Navigation & Footer
    footer      Footer
    menu        Menu

    // Publishing
    build_dest      []BuildDest  // Production destinations
    build_dest_dev  []BuildDest  // Development destinations

    // Imports
    imports     []ImportItem
}

pub struct BuildDest {
pub mut:
    path     string
    ssh_name string
}

pub struct Menu {
pub mut:
    title         string
    items         []MenuItem
    logo_alt      string
    logo_src      string
    logo_src_dark string
}

pub struct MenuItem {
pub mut:
    href     string
    to       string
    label    string
    position string  // "left" or "right"
}

pub struct Footer {
pub mut:
    style string  // e.g., "dark" or "light"
    links []FooterLink
}

pub struct FooterLink {
pub mut:
    title string
    items []FooterItem
}

pub struct FooterItem {
pub mut:
    label string
    to    string
    href  string
}

pub struct Announcement {
pub mut:
    content          string
    background_color string
    text_color       string
    is_closeable     bool
}

pub struct ImportItem {
pub mut:
    url     string  // http or git url
    path    string
    dest    string  // location in docs folder
    replace map[string]string
    visible bool = true
}
```

---

## Core Concepts

### Site
A website configuration that contains pages, navigation structure, and metadata. Each site is registered globally and can be retrieved by name.

### Page
A single documentation page with:
- **src**: `collection:page_name` format (unique identifier)
- **label**: Display name in sidebar
- **title**: Display name on page (extracted from markdown if empty)
- **description**: SEO metadata
- **draft**: Hidden from navigation if true
- **category_id**: Links page to a category (0 = root level)

### Category (Section)
Groups related pages together in the navigation sidebar. Categories can be nested and are automatically collapsed/expandable.

```heroscript
!!site.page_category
    path: "Getting Started"
    collapsible: true
    collapsed: false

!!site.page src: "tech:intro"
    category_id: 1  // Links to the category above
```

### Collection
A logical group of pages. Pages reuse the collection once specified:

```heroscript
!!site.page src: "tech:intro"          # Specifies collection "tech"
!!site.page src: "benefits"             # Reuses collection "tech" 
!!site.page src: "components"           # Still uses collection "tech"
!!site.page src: "api:reference"       # Switches to collection "api"
!!site.page src: "endpoints"            # Uses collection "api"
```

---

## HeroScript Syntax

### 1. Site Configuration (Required)

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
    url_home: "/docs"
```

**Parameters:**
- `name` - Internal site identifier (default: 'default')
- `title` - Main site title (shown in browser tab)
- `description` - Site description for SEO
- `tagline` - Short tagline/subtitle
- `favicon` - Path to favicon image
- `image` - Default OG image for social sharing
- `copyright` - Copyright notice
- `url` - Full site URL for Docusaurus
- `base_url` - Base URL path (e.g., "/" or "/docs/")
- `url_home` - Home page path

### 2. Metadata Overrides (Optional)

```heroscript
!!site.config_meta
    title: "My Docs - Technical Reference"
    image: "img/tech-og.png"
    description: "Technical documentation and API reference"
```

Overrides specific metadata for SEO without changing core config.

### 3. Navigation Bar

```heroscript
!!site.navbar
    title: "My Documentation"
    logo_alt: "Site Logo"
    logo_src: "img/logo.svg"
    logo_src_dark: "img/logo-dark.svg"

!!site.navbar_item
    label: "Documentation"
    to: "intro"
    position: "left"

!!site.navbar_item
    label: "API Reference"
    to: "docs/api"
    position: "left"

!!site.navbar_item
    label: "GitHub"
    href: "https://github.com/myorg/myrepo"
    position: "right"
```

**Parameters:**
- `label` - Display text (required)
- `to` - Internal link
- `href` - External URL
- `position` - "left" or "right" in navbar

### 4. Footer Configuration

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
    to: "getting-started"

!!site.footer_item
    title: "Community"
    label: "Discord"
    href: "https://discord.gg/example"

!!site.footer_item
    title: "Legal"
    label: "Privacy"
    href: "https://example.com/privacy"
```

### 5. Announcement Bar (Optional)

Multiple announcements are supported and stored in an array:

```heroscript
!!site.announcement
    content: "🎉 Version 2.0 is now available!"
    background_color: "#20232a"
    text_color: "#fff"
    is_closeable: true
```

**Note:** Each `!!site.announcement` block adds to the `announcements[]` array. Only the first is typically displayed, but all are stored.

### 6. Pages and Categories

#### Simple: Pages Without Categories

```heroscript
!!site.page src: "guides:introduction"
    label: "Getting Started"
    title: "Getting Started"
    description: "Introduction to the platform"

!!site.page src: "installation"
    label: "Installation"
    title: "Installation"
```

#### Advanced: Pages With Categories

```heroscript
!!site.page_category
    path: "Getting Started"
    collapsible: true
    collapsed: false

!!site.page src: "guides:introduction"
    label: "Introduction"
    title: "Introduction"
    description: "Learn the basics"

!!site.page src: "installation"
    label: "Installation"
    title: "Installation"

!!site.page src: "configuration"
    label: "Configuration"
    title: "Configuration"

!!site.page_category
    path: "Advanced Topics"
    collapsible: true
    collapsed: false

!!site.page src: "advanced:performance"
    label: "Performance Tuning"
    title: "Performance Tuning"

!!site.page src: "scaling"
    label: "Scaling Guide"
    title: "Scaling Guide"
```

**Page Parameters:**
- `src` - Source as `collection:page_name` (first page) or just `page_name` (reuse collection)
- `label` - Display label in sidebar (required)
- `title` - Page title (optional, extracted from markdown if not provided)
- `description` - Page description
- `draft` - Hide from navigation (default: false)
- `hide_title` - Don't show title in page (default: false)
- `hide` - Hide page completely (default: false)

**Category Parameters:**
- `path` - Category path/label (required)
- `collapsible` - Allow collapsing (default: true)
- `collapsed` - Initially collapsed (default: false)

### 7. Content Imports

```heroscript
!!site.import
    url: "https://github.com/example/external-docs"
    path: "/local/path/to/repo"
    dest: "external"
    replace: "PROJECT_NAME:My Project,VERSION:1.0.0"
    visible: true
```

### 8. Publishing Destinations

```heroscript
!!site.publish
    path: "/var/www/html/docs"
    ssh_name: "production"

!!site.publish_dev
    path: "/tmp/docs-preview"
```

---

## Common Patterns

### Pattern 1: Multi-Section Technical Documentation

```heroscript
!!site.config
    name: "tech_docs"
    title: "Technical Documentation"

!!site.page_category
    path: "Getting Started"
    collapsible: true
    collapsed: false

!!site.page src: "docs:intro"
    label: "Introduction"
    title: "Introduction"

!!site.page src: "installation"
    label: "Installation"
    title: "Installation"

!!site.page_category
    path: "Core Concepts"
    collapsible: true
    collapsed: false

!!site.page src: "concepts:architecture"
    label: "Architecture"
    title: "Architecture"

!!site.page src: "components"
    label: "Components"
    title: "Components"

!!site.page_category
    path: "API Reference"
    collapsible: true
    collapsed: false

!!site.page src: "api:rest"
    label: "REST API"
    title: "REST API"

!!site.page src: "graphql"
    label: "GraphQL"
    title: "GraphQL"
```

### Pattern 2: Simple Blog/Knowledge Base

```heroscript
!!site.config
    name: "blog"
    title: "Knowledge Base"

!!site.page src: "articles:first_post"
    label: "Welcome to Our Blog"
    title: "Welcome to Our Blog"

!!site.page src: "second_post"
    label: "Understanding the Basics"
    title: "Understanding the Basics"

!!site.page src: "third_post"
    label: "Advanced Techniques"
    title: "Advanced Techniques"
```

### Pattern 3: Project with External Imports

```heroscript
!!site.config
    name: "project_docs"
    title: "Project Documentation"

!!site.import
    url: "https://github.com/org/shared-docs"
    dest: "shared"
    visible: true

!!site.page_category
    path: "Product Guide"
    collapsible: true
    collapsed: false

!!site.page src: "docs:overview"
    label: "Overview"
    title: "Overview"

!!site.page src: "features"
    label: "Features"
    title: "Features"

!!site.page_category
    path: "Shared Resources"
    collapsible: true
    collapsed: false

!!site.page src: "shared:common"
    label: "Common Patterns"
    title: "Common Patterns"
```

---

## File Organization

### Recommended Ebook Structure

The modern ebook structure uses `.hero` files for configuration and `.heroscript` files for page definitions:

```
my_ebook/
├── scan.hero              # !!doctree.scan - collection scanning
├── config.hero            # !!site.config - site configuration
├── menus.hero             # !!site.navbar and !!site.footer
├── include.hero           # !!docusaurus.define and !!doctree.export
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
!!doctree.scan path:"../../collections/my_collection"
```

### Example include.hero

```heroscript
// Include shared configuration (optional)
!!play.include path:'../../heroscriptall' replace:'SITENAME:my_ebook'

// Or define directly
!!docusaurus.define name:'my_ebook'

!!doctree.export include:true
```

### Running an Ebook

```bash
# Development server
hero docs -d -p /path/to/my_ebook

# Build for production
hero docs -p /path/to/my_ebook
```
