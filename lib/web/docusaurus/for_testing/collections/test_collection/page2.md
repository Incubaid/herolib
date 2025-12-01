# Page 2: Basic Concepts

This page covers the basic concepts of the documentation system.

## Link Syntax

In herolib, links between pages use the format:

```
[Link Text](collection_name:page_name)
```

For example, to link to `page3` in `test_collection`:

```markdown
[Go to Page 3](test_collection:page3)
```

## How It Works

1. The parser identifies links with the `collection:page` format
2. During site generation, these are resolved to actual file paths
3. Docusaurus receives properly formatted relative links

## Navigation

**Previous:** [Page 1: Introduction](test_collection:page1)

**Next:** [Page 3: Configuration](test_collection:page3)

