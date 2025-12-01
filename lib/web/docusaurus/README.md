## Docusaurus Module with HeroLib

This module allows you to build and manage Docusaurus websites using a generic configuration layer provided by `lib/web/site`.

### Hero Command (Recommended)

For quick setup and development, use the hero command:

```bash
# Start development server
hero docs -d -p /path/to/your/ebook

# Build for production
hero docs -p /path/to/your/ebook

# Build and publish
hero docs -bp -p /path/to/your/ebook
```

---

## Ebook Directory Structure

The recommended structure for an ebook follows this pattern:

```
my_ebook/
├── scan.hero              # DocTree collection scanning
├── config.hero            # Site configuration
├── menus.hero             # Navbar and footer configuration
├── include.hero           # Docusaurus define and doctree export
├── 1_intro.heroscript     # Page definitions (numbered for ordering)
├── 2_concepts.heroscript  # More page definitions
└── 3_advanced.heroscript  # Additional pages
```

### File Descriptions

#### `scan.hero` - Scan Collections

Defines which collections to scan for content:

```heroscript
// Scan local collections
!!doctree.scan path:"../../collections/my_collection"

// Scan remote collections from git
!!doctree.scan git_url:"https://git.example.com/org/repo/src/branch/main/collections/docs"
```

#### `config.hero` - Site Configuration

Core site settings:

```heroscript
!!site.config
    name:"my_ebook"
    title:"My Awesome Ebook"
    tagline:"Documentation made easy"
    url:"https://docs.example.com"
    url_home:"docs/"
    base_url:"/my_ebook/"
    favicon:"img/favicon.png"
    copyright:"© 2024 My Organization"
    default_collection:"my_collection"

!!site.config_meta
    description:"Comprehensive documentation for my project"
    title:"My Ebook - Documentation"
    keywords:"docs, ebook, tutorial"
```

**Note:** When `url_home` ends with `/` (e.g., `docs/`), the first page in the sidebar automatically becomes the landing page. This means both `/docs/` and `/docs/intro` will work.

#### `menus.hero` - Navigation Configuration

```heroscript
!!site.navbar
    title:"My Ebook"

!!site.navbar_item
    label:"Documentation"
    to:"docs/"
    position:"left"

!!site.navbar_item
    label:"GitHub"
    href:"https://github.com/myorg/myrepo"
    position:"right"

!!site.footer
    style:"dark"

!!site.footer_item
    title:"Docs"
    label:"Getting Started"
    to:"docs/"

!!site.footer_item
    title:"Community"
    label:"GitHub"
    href:"https://github.com/myorg/myrepo"
```

#### `include.hero` - Docusaurus Setup

Links to shared configuration or defines docusaurus directly:

```heroscript
// Option 1: Include shared configuration with variable replacement
!!play.include path:'../../heroscriptall' replace:'SITENAME:my_ebook'

// Option 2: Define directly
!!docusaurus.define name:'my_ebook'

!!doctree.export include:true
```

#### Page Definition Files (`*.heroscript`)

Define pages and categories:

```heroscript
// Define a category
!!site.page_category name:'getting_started' label:"Getting Started"

// Define pages (first page specifies collection, subsequent pages reuse it)
!!site.page src:"my_collection:intro"
    title:"Introduction"

!!site.page src:"installation"
    title:"Installation Guide"

!!site.page src:"configuration"
    title:"Configuration"

// New category
!!site.page_category name:'advanced' label:"Advanced Topics"

!!site.page src:"my_collection:performance"
    title:"Performance Tuning"
```

---

## Collections

Collections are directories containing markdown files. They're scanned by DocTree and referenced in page definitions.

```
collections/
├── my_collection/
│   ├── .collection         # Marker file (empty)
│   ├── intro.md
│   ├── installation.md
│   └── configuration.md
└── another_collection/
    ├── .collection
    └── overview.md
```

Pages reference collections using `collection:page` format:

```heroscript
!!site.page src:"my_collection:intro"      # Specifies collection
!!site.page src:"installation"              # Reuses previous collection
!!site.page src:"another_collection:overview"  # Switches collection
```

---

## Legacy Configuration

The older approach using `!!docusaurus.add` is still supported but not recommended:

```heroscript
!!docusaurus.define
    path_build: "/tmp/docusaurus_build"
    path_publish: "/tmp/docusaurus_publish"

!!docusaurus.add
    sitename:"my_site"
    path:"./path/to/site"

!!docusaurus.dev site:"my_site" open:true
```

---

## HeroScript Actions Reference

### `!!doctree.scan`

Scans a directory for markdown collections:

- `path` (string): Local path to scan
- `git_url` (string): Git URL to clone and scan
- `name` (string): DocTree instance name (default: `main`)
- `ignore` (list): Directory names to skip

### `!!doctree.export`

Exports scanned collections:

- `include` (bool): Include content in export (default: `true`)
- `destination` (string): Export directory

### `!!docusaurus.define`

Configures the Docusaurus build environment:

- `name` (string, required): Site name (must match `!!site.config` name)
- `path_build` (string): Build directory path
- `path_publish` (string): Publish directory path
- `reset` (bool): Clean build directory before starting
- `template_update` (bool): Update Docusaurus template
- `install` (bool): Run `bun install`
- `doctree_dir` (string): DocTree export directory

### `!!site.config`

Core site configuration:

- `name` (string, required): Unique site identifier
- `title` (string): Site title
- `tagline` (string): Site tagline
- `url` (string): Full site URL
- `base_url` (string): Base URL path (e.g., `/my_ebook/`)
- `url_home` (string): Home page path (e.g., `docs/`)
- `default_collection` (string): Default collection for pages
- `favicon` (string): Favicon path
- `copyright` (string): Copyright notice

### `!!site.page`

Defines a documentation page:

- `src` (string, required): Source as `collection:page` or just `page` (reuses previous collection)
- `title` (string): Page title
- `description` (string): Page description
- `draft` (bool): Hide from navigation
- `hide_title` (bool): Don't show title on page

### `!!site.page_category`

Defines a sidebar category:

- `name` (string, required): Category identifier
- `label` (string): Display label
- `position` (int): Sort order

---

## See Also

- `lib/web/site` - Generic site configuration module
- `lib/data/doctree` - DocTree collection management
