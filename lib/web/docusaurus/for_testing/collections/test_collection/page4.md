# Page 4: Advanced Features

This page covers advanced features of the linking mechanism.

## Cross-Collection Links

You can link to pages in different collections:

```markdown
[Link to other collection](other_collection:some_page)
```

## Categories

Pages can be organized into categories:

```heroscript
!!site.page_category name:'advanced' label:"Advanced Topics"

!!site.page name:'page4' collection:'test_collection'
    title:"Advanced Features"
```

## Multiple Link Formats

The system supports various link formats:

1. **Collection links:** `[text](collection:page)`
2. **Relative links:** `[text](./other_page.md)`
3. **External links:** `[text](https://example.com)`

## Navigation

**Previous:** [Page 3: Configuration](test_collection:page3)

**Next:** [Page 5: Troubleshooting](test_collection:page5)

