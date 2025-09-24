## Docusaurus Module with HeroLib

This module allows you to build and manage Docusaurus websites using a generic configuration layer provided by `lib/web/site`.

### Workflow

1. **Configure Your Site**: Define your site's metadata, navigation, footer, pages, and content sources using `!!site.*` actions in a `.heroscript` file. This creates a generic site definition.
2. **Define Docusaurus Build**: Use `!!docusaurus.define` to specify build paths and other factory-level settings.
3. **Link Site to Docusaurus**: Use `!!docusaurus.add` to link your generic site configuration to the Docusaurus factory. This tells HeroLib to build this specific site using Docusaurus.
4. **Run Actions**: Use actions like `!!docusaurus.dev` or `!!docusaurus.build` to generate and serve your site.

### Hero Command (Recommended)

For quick setup and development, use the hero command:

```bash
# Start development server
hero docusaurus -d -path /path/to/your/site

# Build for production
hero docusaurus -b -path /path/to/your/site

# Build and publish
hero docusaurus -bp -path /path/to/your/site
```


### Example HeroScript

```heroscript

// Define the Docusaurus build environment, is optional
!!docusaurus.define
    path_build: "/tmp/docusaurus_build"
    path_publish: "/tmp/docusaurus_publish"
    reset: 1
    install: 1
    template_update: 1

!!docusaurus.add
    sitename:"my_site"
    path:"./path/to/my/site/source"
    path_publish: "/tmp/docusaurus_publish"                                                 //optional
    git_url:"https://git.threefold.info/tfgrid/docs_tfgrid4/src/branch/main/ebooks/tech"    //optional: can use git to pull the site source
    git_root:"/tmp/code"                                                                    //optional: where to clone git repo
    git_reset:1                                                                             //optional: reset git repo
    git_pull:1                                                                              //optional: pull latest changes
    play:true                                                                               //required when using git_url: process heroscript files from source path


// Run the development server
!!docusaurus.dev site:"my_site" open:true watch_changes:true

```

## see sites to define a site

the site needs to be defined following the generic site definition, see the `lib/web/site` module for more details.

```heroscript

//Configure the site using the generic 'site' module
!!site.config
    name: "my_site"
    title: "My Awesome Docs"
    tagline: "The best docs ever"
    url: "https://docs.example.com"
    base_url: "/"
    copyright: "Example Corp"

!!site.menu_item
    label: "Homepage"
    href: "https://example.com"
    position: "right"

// ... add footer, pages, etc. using !!site.* actions ...

```

### Heroscript Actions

- `!!docusaurus.define`: Configures a Docusaurus factory instance.
  - `name` (string): Name of the factory (default: `default`).
  - `path_build` (string): Path to build the site.
  - `path_publish` (string): Path to publish the final build.
  - `reset` (bool): If `true`, clean the build directory before starting.
  - `template_update` (bool): If `true`, update the Docusaurus template.
  - `install` (bool): If `true`, run `bun install`.

- `!!docusaurus.add`: Links a configured site to the Docusaurus factory.
  - `site` (string, required): The name of the site defined in `!!site.config`.
  - `path` (string, required): The local filesystem path to the site's source directory (e.g., for `static/` folder).

- `!!docusaurus.dev`: Runs the Docusaurus development server.
  - `site` (string, required): The name of the site to run.
  - `host` (string): Host to bind to (default: `localhost`).
  - `port` (int): Port to use (default: `3000`).
  - `open` (bool): Open the site in a browser.
  - `watch_changes` (bool): Watch for source file changes and auto-reload.

- `!!docusaurus.build`: Builds the static site for production.
  - `site` (string, required): The name of the site to build.
