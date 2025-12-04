# HeroLib Docusaurus Ebook Manual for AI Prompts

This manual provides a comprehensive guide on how to leverage HeroLib's Docusaurus integration, Doctree, and HeroScript to create and manage technical ebooks, optimized for AI-driven content generation and project management.

## Quick Start - Recommended Ebook Structure

The recommended directory structure for an ebook:

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

**Running an ebook:**

```bash
# Start development server
hero docs -d -p /path/to/my_ebook

# Build for production
hero docs -p /path/to/my_ebook
```

## 1. Core Concepts

To effectively create ebooks with HeroLib, it's crucial to understand the interplay of three core components:

* **HeroScript**: A concise scripting language used to define the structure, configuration, and content flow of your Docusaurus site. It acts as the declarative interface for the entire process. Files use `.hero` extension for configuration and `.heroscript` for page definitions.
* **Docusaurus**: A popular open-source static site generator. HeroLib uses Docusaurus as the underlying framework to render your ebook content into a navigable website.
* **DocTree**: HeroLib's document collection layer. DocTree scans and exports markdown "collections" and "pages" that Docusaurus consumes.

## 2. Setting Up a Docusaurus Project with HeroLib

The `docusaurus` module in HeroLib provides the primary interface for managing your ebook projects.

### 2.1. Defining the Docusaurus Factory (`docusaurus.define`)

The `docusaurus.define` HeroScript directive configures the global settings for your Docusaurus build environment. This is typically used once at the beginning of your main HeroScript configuration.

**HeroScript Example:**

```heroscript
!!docusaurus.define
    name:"my_ebook"                  // must match the site name from !!site.config
    path_build: "/tmp/my_ebook_build"
    path_publish: "/tmp/my_ebook_publish"
    reset: true                      // clean build dir before building (optional)
    install: true                    // run bun install if needed (optional)
    template_update: true            // update the Docusaurus template (optional)
    doctree_dir: "/tmp/doctree_export"   // where DocTree exports collections
    use_doctree: true                  // use DocTree as content backend
```

**Arguments:**

* `name` (string, required): The site/factory name. Must match the `name` used in `!!site.config` so Docusaurus can find the corresponding site definition.
* `path_build` (string, optional): The local path where the Docusaurus site will be built. Defaults to `~/hero/var/docusaurus/build`.
* `path_publish` (string, optional): The local path where the final Docusaurus site will be published (e.g., for deployment). Defaults to `~/hero/var/docusaurus/publish`.
* `reset` (boolean, optional): If `true`, clean the build directory before starting.
* `install` (boolean, optional): If `true`, run dependency installation (e.g., `bun install`).
* `template_update` (boolean, optional): If `true`, update the Docusaurus template.
* `doctree_dir` (string, optional): Directory where DocTree exports collections (used by the DocTree client in `lib/data/doctree/client`).
* `use_doctree` (boolean, optional): If `true`, use the DocTree client as the content backend (default behavior).

### 2.2. Adding a Docusaurus Site (`docusaurus.add`)

The `docusaurus.add` directive defines an individual Docusaurus site (your ebook). You can specify the source of your documentation content, whether it's a local path or a Git repository.

**HeroScript Example (Local Content):**

```heroscript
!!docusaurus.add
    name:"my_local_ebook"
    path:"./my_ebook_content" // Path to your local docs directory
    open:true // Open in browser after generation
```

**HeroScript Example (Git Repository Content):**

```heroscript
!!docusaurus.add
    name:"tfgrid_tech_ebook"
    git_url:"https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/ebooks/tech"
    git_reset:true // Reset Git repository before pulling
    git_pull:true // Pull latest changes
    git_root:"/tmp/git_clones" // Optional: specify a root directory for git clones
```

**Arguments:**

* `name` (string, optional): A unique name for your Docusaurus site/ebook. Defaults to "main".
* `path` (string, optional): The local file system path to the root of your documentation content (e.g., where your `docs` and `cfg` directories are).
* `git_url` (string, optional): A Git URL to a repository containing your documentation content. HeroLib will clone/pull this repository.
* `git_reset` (boolean, optional): If `true`, the Git repository will be reset to a clean state before pulling. Default is `false`.
* `git_pull` (boolean, optional): If `true`, the Git repository will be pulled to get the latest changes. Default is `false`.
* `git_root` (string, optional): An optional root directory where Git repositories will be cloned.
* `nameshort` (string, optional): A shorter name for the Docusaurus site. Defaults to the value of `name`.
* `path_publish` (string, optional): Overrides the factory's `path_publish` for this specific site.
* `production` (boolean, optional): Overrides the factory's `production` setting for this specific site.
* `watch_changes` (boolean, optional): If `true`, HeroLib will watch for changes in your source `docs` directory and trigger rebuilds. Default is `true`.
* `update` (boolean, optional): If `true`, this specific documentation will be updated. Default is `false`.
* `open` (boolean, optional): If `true`, the Docusaurus site will be opened in your default browser after generation/development server start. Default is `false`.
* `init` (boolean, optional): If `true`, the Docusaurus site will be initialized (e.g., creating missing `docs` directories). Default is `false`.

## 3. Structuring Content with HeroScript and Doctree

The actual content and structure of your ebook are defined using HeroScript directives within your site's configuration files (e.g., in a `cfg` directory within your `path` or `git_url` source).

### 3.1. Site Configuration (`site.config`, `site.config_meta`)

These directives define the fundamental properties and metadata of your Docusaurus site.

**HeroScript Example:**

```heroscript
!!site.config
    name:"my_awesome_ebook"
    title:"My Awesome Ebook Title"
    tagline:"A comprehensive guide to everything."
    url:"https://my-ebook.example.com"
    url_home:"docs/"
    base_url:"/my-ebook/"
    favicon:"img/favicon.png"
    copyright:"© 2024 My Organization"

!!site.config_meta
    description:"This ebook covers advanced topics in AI and software engineering."
    image:"https://my-ebook.example.com/img/social_share.png"
    title:"Advanced AI & Software Engineering Ebook"
    keywords:"AI, software, engineering, manual, guide"
```

**Arguments:**

* **`site.config`**:
  * `name` (string, required): Unique identifier for the site.
  * `title` (string, optional): Main title of the site. Defaults to "My Documentation Site".
  * `description` (string, optional): General site description.
  * `tagline` (string, optional): Short tagline for the site.
  * `favicon` (string, optional): Path to the favicon. Defaults to "img/favicon.png".
  * `image` (string, optional): General site image (e.g., for social media previews). Defaults to "img/tf_graph.png".
  * `copyright` (string, optional): Copyright notice. Defaults to "© [Current Year] Example Organization".
  * `url` (string, optional): The main URL where the site will be hosted.
  * `base_url` (string, optional): The base URL for Docusaurus (e.g., `/` or `/my-ebook/`).
  * `url_home` (string, optional): The path to the home page relative to `base_url`.
* **`site.config_meta`**: Overrides for specific SEO metadata.
  * `title` (string, optional): Specific title for SEO (e.g., `<meta property="og:title">`).
  * `image` (string, optional): Specific image for SEO (e.g., `<meta property="og:image">`).
  * `description` (string, optional): Specific description for SEO.
  * `keywords` (string, optional): Comma-separated keywords for SEO.

### 3.2. Navigation Bar (`site.navbar`, `site.navbar_item`)

Define the main navigation menu of your Docusaurus site.

**HeroScript Example:**

```heroscript
!!site.navbar
    title:"Ebook Navigation"
    logo_alt:"Ebook Logo"
    logo_src:"img/logo.svg"
    logo_src_dark:"img/logo_dark.svg"

!!site.navbar_item
    label:"Introduction"
    to:"/docs/intro" // Internal Docusaurus path
    position:"left"

!!site.navbar_item
    label:"External Link"
    href:"https://example.com/external" // External URL
    position:"right"
```

**Arguments:**

* **`site.navbar`**:
  * `title` (string, optional): Title displayed in the navbar. Defaults to `site.config.title`.
  * `logo_alt` (string, optional): Alt text for the logo.
  * `logo_src` (string, optional): Path to the light mode logo.
  * `logo_src_dark` (string, optional): Path to the dark mode logo.
* **`site.navbar_item`**:
  * `label` (string, required): Text displayed for the menu item.
  * `href` (string, optional): External URL for the link.
  * `to` (string, optional): Internal Docusaurus path (e.g., `/docs/my-page`).
  * `position` (string, optional): "left" or "right" for placement in the navbar. Defaults to "right".

### 3.3. Footer (`site.footer`, `site.footer_item`)

Configure the footer section of your Docusaurus site.

**HeroScript Example:**

```heroscript
!!site.footer
    style:"dark" // "dark" or "light"

!!site.footer_item
    title:"Resources" // Grouping title for footer links
    label:"API Documentation"
    href:"https://api.example.com/docs"

!!site.footer_item
    title:"Community"
    label:"GitHub"
    href:"https://github.com/my-org"
```

**Arguments:**

* **`site.footer`**:
  * `style` (string, optional): "dark" or "light" style for the footer. Defaults to "dark".
* **`site.footer_item`**:
  * `title` (string, required): The title under which this item will be grouped in the footer.
  * `label` (string, required): Text displayed for the footer link.
  * `href` (string, optional): External URL for the link.
  * `to` (string, optional): Internal Docusaurus path.

### 3.4. Publish Destinations (`site.publish`, `site.publish_dev`)

Specify where the built Docusaurus site should be deployed. This typically involves an SSH connection defined elsewhere (e.g., `!!site.ssh_connection`).

**HeroScript Example:**

```heroscript
!!site.publish
    ssh_name:"production_server" // Name of a pre-defined SSH connection
    path:"/var/www/my-ebook"     // Remote path on the server

!!site.publish_dev
    ssh_name:"dev_server"
    path:"/tmp/dev-ebook"
```

**Arguments:**

* `ssh_name` (string, required): The name of the SSH connection to use for deployment.
* `path` (string, required): The destination path on the remote server.

### 3.5. Importing External Content (`site.import`)

This powerful feature allows you to pull markdown content and assets from other Git repositories directly into your Docusaurus site's `docs` directory, with optional text replacement. This is ideal for integrating shared documentation or specifications.

**HeroScript Example:**

```heroscript
!!site.import
    url:'https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/collections/cloud_reinvented'
    dest:'cloud_reinvented' // Destination subdirectory within your Docusaurus docs folder
    replace:'NAME:MyName, URGENCY:red' // Optional: comma-separated key:value pairs for text replacement
```

**Arguments:**

* `url` (string, required): The Git URL of the repository or specific path within a repository to import.
* `dest` (string, required): The subdirectory within your Docusaurus `docs` folder where the imported content will be placed.
* `replace` (string, optional): A comma-separated string of `KEY:VALUE` pairs. During import, all occurrences of `${KEY}` in the imported content will be replaced with `VALUE`.

### 3.6. Defining Pages and Categories (`site.page_category`, `site.page`)

This is where you define the actual content pages and how they are organized into categories within your Docusaurus sidebar.

**HeroScript Example:**

```heroscript
// Define a category
!!site.page_category name:'introduction' label:"Introduction to Ebook"

// Define pages - first page specifies collection, subsequent pages reuse it
!!site.page src:"my_collection:chapter_1_overview"
    title:"Chapter 1: Overview"
    description:"A brief introduction to the ebook's content."

!!site.page src:"chapter_2_basics"
    title:"Chapter 2: Basics"

// New category with new collection
!!site.page_category name:'advanced' label:"Advanced Topics"

!!site.page src:"advanced_collection:performance"
    title:"Performance Tuning"
    hide_title:true
```

**Arguments:**

* **`site.page_category`**:
  * `name` (string, required): Category identifier (used internally).
  * `label` (string, required): The display name for the category in the sidebar.
  * `position` (int, optional): The order of the category in the sidebar (auto-incremented if omitted).
* **`site.page`**:
  * `src` (string, required): **Crucial for DocTree/collection integration.** Format: `collection_name:page_name` for the first page, or just `page_name` to reuse the previous collection.
  * `title` (string, optional): The title of the page. If not provided, HeroLib extracts it from the markdown `# Heading` or uses the page name.
  * `description` (string, optional): A short description for the page, used in frontmatter.
  * `hide_title` (boolean, optional): If `true`, the title will not be displayed on the page itself.
  * `draft` (boolean, optional): If `true`, the page will be hidden from navigation.

### 3.7. Collections and DocTree/Doctree Integration

The `site.page` directive's `src` parameter (`collection_name:page_name`) is the bridge to your content collections.

**Current default: DocTree export**

1. **Collections**: DocTree exports markdown files into collections under an `export_dir` (see `lib/data/doctree/client`).
2. **Export step**: A separate process (DocTree) writes the collections into `doctree_dir` (e.g., `/tmp/doctree_export`), following the `content/` + `meta/` structure.
3. **Docusaurus consumption**: The Docusaurus module uses the DocTree client (`doctree_client`) to resolve `collection_name:page_name` into markdown content and assets when generating docs.

**Alternative: Doctree/`doctreeclient`**

In older setups, or when explicitly configured, Doctree and `doctreeclient` can still be used to provide the same `collection:page` model:

1. **Collections**: Doctree organizes markdown files into logical groups called "collections." A collection is typically a directory containing markdown files and an empty `.collection` file.
2. **Scanning**: You define which collections Doctree should scan using `!!doctree.scan` in a HeroScript file (e.g., `doctree.heroscript`):

    ```heroscript
    !!doctree.scan git_url:"https://git.ourworld.tf/tfgrid/docs_tfgrid4/src/branch/main/collections"
    ```

    This will pull the `collections` directory from the specified Git URL and make its contents available to Doctree.
3. **Page Retrieval**: When `site.page` references `src:"my_collection:my_page"`, the client (`doctree_client` or `doctreeclient`, depending on configuration) fetches the content of `my_page.md` from the `my_collection` collection.

## 4. Building and Developing Your Ebook

Once your HeroScript configuration is set up, HeroLib provides commands to build and serve your Docusaurus ebook.

### 4.1. Generating Site Files (`site.generate()`)

The `site.generate()` function (called internally by `build`, `dev`, etc.) performs the core file generation:

* Copies Docusaurus template files.
* Copies your site's `src` and `static` assets.
* Generates Docusaurus configuration JSON files (`main.json`, `navbar.json`, `footer.json`) from your HeroScript `site.config`, `site.navbar`, and `site.footer` directives.
* Copies your source `docs` directory.
* Processes `site.page` and `site.page_category` directives using the `sitegen` module to create the final markdown files and `_category_.json` files in the Docusaurus `docs` directory, fetching content from Doctree.
* Handles `site.import` directives, pulling external content and performing replacements.

### 4.2. Local Development

HeroLib integrates with Docusaurus's development server for live preview.

**HeroScript Example:**

can be stored as example_docusaurus.vsh and then used to generate and develop an ebook

```v
#!/usr/bin/env -S v -n -w -gc none  -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.web.docusaurus
import os

const cfgpath = os.dir(@FILE)

docusaurus.new(
 heroscript: '

 // !!docusaurus.define
 //  path_build: "/tmp/docusaurus_build"
 //  path_publish: "/tmp/docusaurus_publish"

 !!docusaurus.add name:"tfgrid_docs" 
  path:"${cfgpath}"

 !!docusaurus.dev

 '
)!

```

the following script suggest to call it do.vsh and put in directory of where the ebook is

```v
#!/usr/bin/env -S v -n -w -gc none  -cg -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.web.docusaurus

const cfgpath = os.dir(@FILE) + '/cfg'

docusaurus.new(heroscript_path:cfgpath)!
```

by just called do.vsh we can execute on the ebook
