# Page 3: Configuration

This page explains configuration options for the documentation system.

## Site Configuration

The site is configured using heroscript files:

```heroscript
!!site.config
    name:"test_site"
    title:"Test Documentation"
    base_url:"/test/"
    url_home:"docs/page1"
```

## Page Definitions

Each page is defined using the `!!site.page` action:

```heroscript
!!site.page src:"test_collection:page1"
    title:"Introduction"
```

## Important Settings

| Setting | Description |
|---------|-------------|
| `name` | Unique page identifier |
| `collection` | Source collection name |
| `title` | Display title in sidebar |

## Navigation

**Previous:** [Page 2: Basic Concepts](test_collection:page2)

**Next:** [Page 4: Advanced Features](test_collection:page4)

