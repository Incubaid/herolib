# Site Module


## config heroscript

```yaml
!!site.config
    name:"ThreeFold DePIN Tech"
    description:"ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet."
    tagline:"Geo Aware Internet Platform"
    favicon:"img/favicon.png"
    image:"img/tf_graph.png"
    copyright:"ThreeFold"

!!site.menu
    title:"ThreeFold DePIN Tech"
    logo_alt:"ThreeFold Logo"
    logo_src:"img/logo.svg"
    logo_src_dark:"img/new_logo_tft.png"

!!site.menu_item
    label:"ThreeFold.io"
    href:"https://threefold.io"
    position:"right"

!!site.menu_item
    label:"Mycelium Network"
    href:"https://mycelium.threefold.io/"
    position:"right"

!!site.menu_item
    label:"AI Box"
    href:"https://aibox.threefold.io/"
    position:"right"

!!site.footer
    style:"dark"

!!site.footer_item
    title:"Docs"
    label:"Introduction"
    href:"https://docs.threefold.io/docs/introduction"

!!site.footer_item
    title:"Docs"
    label:"Litepaper"
    href:"https://docs.threefold.io/docs/litepaper/"

!!site.footer_item
    title:"Features"
    label:"Become a Farmer"
    href:"https://docs.threefold.io/docs/category/become-a-farmer"

!!site.footer_item
    title:"Features"
    label:"Components"
    href:"https://docs.threefold.io/docs/category/components"


!!site.footer_item
    title:"Web"
    label:"ThreeFold.io"
    href:"https://threefold.io"

!!site.footer_item
    title:"Web"
    label:"Dashboard"
    href:"https://dashboard.grid.tf"

!!site.collections
    url:"https://github.com/example/external-docs"
    replace:"PROJECT_NAME:My Project, VERSION:1.0.0"
```

## site structure

```yaml
!!site.page name:intro 
    description:"ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet."

#next is example where we use all properties, folder is where the page is located, prio is the order of the page, if not used the filled in from order in which we parse this config file
!!site.page name:mycelium draft:true folder:"/specs/components" prio:4
    content:"the page content itself, only for small pages"
    title:"Mycelium as Title"
    description:"..."

!!site.page name:fungistor folder:"/specs/components" prio:1
    src:"mycollection:mycelium.md"
    title:"fungistor as Title"
    description:"...."

!!site.page name:fungistor folder:"/specs/components" prio:1
    src:"mycollection:mycelium" //can be without .md
    title:"fungistor as Title"
    description:"..."

```

## factory

```v
import freeflowuniverse.herolib.web.site
mut mysite := site.new()!

```

## how to use with plbook

```v
import freeflowuniverse.herolib.core.playbook
import freeflowuniverse.herolib.web.site
// path string
// text string
// git_url string
// git_pull bool
// git_branch string
// git_reset bool
// session  ?&base.Session      is optional
mut plbook := playbook.new( "....")!

site.play(mut plbook)!

```

## example json

```json
{
    "name": "depin",
    "title": "Documentation Site",
    "description": "ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet.",
    "tagline": "Geo Aware Internet Platform",
    "favicon": "img/favicon.png",
    "image": "img/tf_graph.png",
    "copyright": "ThreeFold",
    "footer": {
        "style": "dark",
        "links": [
            {
                "title": "Docs",
                "items": [
                    {
                        "label": "Introduction",
                        "to": "intro",
                        "href": ""
                    },
                    {
                        "label": "Litepaper",
                        "to": "",
                        "href": "https://docs.threefold.io/docs/litepaper/"
                    },
                    {
                        "label": "Roadmap",
                        "to": "",
                        "href": "https://docs.threefold.io/docs/roadmap"
                    },
                    {
                        "label": "Manual",
                        "to": "",
                        "href": "https://manual.grid.tf/"
                    }
                ]
            },
            {
                "title": "Features",
                "items": [
                    {
                        "label": "Become a Farmer",
                        "to": "",
                        "href": "https://docs.threefold.io/docs/category/become-a-farmer"
                    },
                    {
                        "label": "Components",
                        "to": "",
                        "href": "https://docs.threefold.io/docs/category/components"
                    },
                    {
                        "label": "Technology",
                        "to": "",
                        "href": "https://threefold.info/tech/"
                    },
                    {
                        "label": "Tokenomics",
                        "to": "",
                        "href": "https://docs.threefold.io/docs/tokens/tokenomics"
                    }
                ]
            },
            {
                "title": "Web",
                "items": [
                    {
                        "label": "ThreeFold.io",
                        "to": "",
                        "href": "https://threefold.io"
                    },
                    {
                        "label": "Dashboard",
                        "to": "",
                        "href": "https://dashboard.grid.tf"
                    },
                    {
                        "label": "GitHub",
                        "to": "",
                        "href": "https://github.com/threefoldtech/home"
                    },
                    {
                        "label": "Mycelium Network",
                        "to": "",
                        "href": "https://mycelium.threefold.io/"
                    },
                    {
                        "label": "AI Box",
                        "to": "",
                        "href": "https://www2.aibox.threefold.io/"
                    }
                ]
            }
        ]
    },
    "menu": {
        "title": "ThreeFold DePIN Tech",
        "items": [
            {
                "href": "https://threefold.io",
                "to": "",
                "label": "ThreeFold.io",
                "position": "right"
            },
            {
                "href": "https://mycelium.threefold.io/",
                "to": "",
                "label": "Mycelium Network",
                "position": "right"
            },
            {
                "href": "https://aibox.threefold.io/",
                "to": "",
                "label": "AI Box",
                "position": "right"
            }
        ]
    },
    "import_collections": [
        {
            "url": "https://github.com/example/external-docs",
            "path": "",
            "dest": "",
            "replace": {
                "PROJECT_NAME": "My Project",
                "VERSION": "1.0.0"
            },
            "visible": false
        }
    ],
    "pages": [
        {
            "name": "intro",
            "content": "",
            "title": "",
            "description": "ThreeFold is laying the foundation for a geo aware Web 4, the next generation of the Internet.",
            "draft": false,
            "folder": "",
            "prio": 0,
            "src": ""
        },
        {
            "name": "mycelium",
            "content": "the page content itself, only for small pages",
            "title": "Mycelium as Title",
            "description": "...",
            "draft": true,
            "folder": "/specs/components",
            "prio": 4,
            "src": ""
        },
        {
            "name": "fungistor",
            "content": "",
            "title": "fungistor as Title",
            "description": "....",
            "draft": false,
            "folder": "/specs/components",
            "prio": 1,
            "src": "mycollection:mycelium.md"
        },
        {
            "name": "fungistor",
            "content": "",
            "title": "fungistor as Title",
            "description": "...",
            "draft": false,
            "folder": "/specs/components",
            "prio": 1,
            "src": "mycollection:mycelium"
        }
    ]
}
```