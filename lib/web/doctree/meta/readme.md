# Site Module

The Site module provides a structured way to define website configurations, navigation menus, pages, and sections using HeroScript. It's designed to work with static site generators like Docusaurus.


## Quick Start

### Minimal HeroScript Example

```heroscript
!!site.config
    name: "my_docs"
    title: "My Documentation"

!!site.page src: "docs:introduction"
    title: "Getting Started"

!!site.page src: "setup"
    title: "Installation"
```

### Processing with V Code

```v
#!/usr/bin/env -S v -n -w -gc none -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.playbook
import incubaid.herolib.web.site
import incubaid.herolib.ui.console

// Process HeroScript file
mut plbook := playbook.new(path: './site_config.heroscript')!

// Execute site configuration
site.play(mut plbook)!

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

```heroscript
!!site.announcement
    content: "🎉 Version 2.0 is now available!"
    background_color: "#20232a"
    text_color: "#fff"
    is_closeable: true
```

### 6. Pages and Categories

#### Simple: Pages Without Categories

```heroscript
!!site.page src: "guides:introduction"
    title: "Getting Started"
    description: "Introduction to the platform"

!!site.page src: "installation"
    title: "Installation"

!!site.page src: "configuration"
    title: "Configuration"
```

#### Advanced: Pages With Categories

```heroscript
!!site.page_category
    name: "basics"
    label: "Getting Started"

!!site.page src: "guides:introduction"
    title: "Introduction"
    description: "Learn the basics"

!!site.page src: "installation"
    title: "Installation"

!!site.page src: "configuration"
    title: "Configuration"

!!site.page_category
    name: "advanced"
    label: "Advanced Topics"

!!site.page src: "advanced:performance"
    title: "Performance Tuning"

!!site.page src: "scaling"
    title: "Scaling Guide"
```

**Page Parameters:**
- `src` - Source as `collection:page` (first page) or just `page_name` (reuse collection)
- `title` - Page title (optional, extracted from markdown if not provided)
- `description` - Page description
- `draft` - Hide from navigation (default: false)
- `hide_title` - Don't show title in page (default: false)

**Category Parameters:**
- `name` - Category identifier (required)
- `label` - Display label (auto-generated from name if omitted)
- `position` - Sort order (auto-incremented if omitted)

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
    name: "getting_started"
    label: "Getting Started"

!!site.page src: "docs:intro"
    title: "Introduction"

!!site.page src: "installation"
    title: "Installation"

!!site.page_category
    name: "concepts"
    label: "Core Concepts"

!!site.page src: "concepts:architecture"
    title: "Architecture"

!!site.page src: "components"
    title: "Components"

!!site.page_category
    name: "api"
    label: "API Reference"

!!site.page src: "api:rest"
    title: "REST API"

!!site.page src: "graphql"
    title: "GraphQL"
```

### Pattern 2: Simple Blog/Knowledge Base

```heroscript
!!site.config
    name: "blog"
    title: "Knowledge Base"

!!site.page src: "articles:first_post"
    title: "Welcome to Our Blog"

!!site.page src: "second_post"
    title: "Understanding the Basics"

!!site.page src: "third_post"
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
    name: "product"
    label: "Product Guide"

!!site.page src: "docs:overview"
    title: "Overview"

!!site.page src: "features"
    title: "Features"

!!site.page_category
    name: "resources"
    label: "Shared Resources"

!!site.page src: "shared:common"
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

