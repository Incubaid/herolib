# Usage Guide

This guide covers how to develop and manage your **${args.title}** documentation site.

## Hero CLI Commands

### Development Server

Start the development server to preview your changes:

```bash
hero docs -d -path ~/path/to/${args.name}/ebooks/${args.name}
```

Access your site at: `http://localhost:3000/${args.name}/docs/`

### Build Static Site

Build the static site for production:

```bash
hero docs -b -path ~/path/to/${args.name}/ebooks/${args.name}
```

### Build and Publish

Build, validate links, and deploy to production:

```bash
hero docs -bp -path ~/path/to/${args.name}/ebooks/${args.name}
```

## Project Structure

```
${args.name}/
├── collections/${args.name}/    # Markdown content
│   ├── .collection              # Collection marker (required)
│   ├── introduction.md          # Introduction page
│   ├── usage.md                 # This file
│   └── support.md               # Support page
├── ebooks/${args.name}/         # Site configuration
│   ├── config.hero              # Main site config
│   ├── menus.hero               # Navigation menus
│   ├── pages.hero               # Page definitions
│   └── scan.hero                # Atlas scan config
└── docusaurusbase/static/img/   # Logos and images
```

## Adding New Pages

### 1. Create Markdown File

Add a new `.md` file to your collection:

```bash
touch collections/${args.name}/my_new_page.md
```

### 2. Add Page Definition

Edit `ebooks/${args.name}/pages.hero` to include the new page:

```heroscript
!!site.page src:"${args.name}:my_new_page"
    title:"My New Page"
    position:4
```

### 3. Preview Changes

Run the dev server to see your changes:

```bash
hero docs -d -path ~/path/to/${args.name}/ebooks/${args.name}
```

## Linking Between Pages

Use the `collection:page_name` format for links:

```markdown
[Link Text](collection_name:page_name)
[Link Text](other_collection:page_name)
```

Example: `[Usage Guide](${args.name}:usage)` links to this page.

## Customization

### Site Configuration

Edit `ebooks/${args.name}/config.hero`:

- `title` - Site title
- `tagline` - Site tagline
- `url` - Production URL
- `base_url` - Base URL path

### Navigation

Edit `ebooks/${args.name}/menus.hero` to customize:

- Navbar items
- Footer links
- Social links

### Static Assets

Add images and logos to `docusaurusbase/static/img/`:

- `logo.svg` - Site logo
- `favicon.svg` - Browser favicon
