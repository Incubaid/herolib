# Page 5: Troubleshooting

This page helps you troubleshoot common issues.

## Common Issues

### Broken Links

If links appear broken, check:

1. The collection name is correct
2. The page name matches the markdown filename (without `.md`)
3. The collection is properly registered in the doctree

### Page Not Found

Ensure the page is defined in your heroscript:

```heroscript
!!site.page name:'page5' collection:'test_collection'
    title:"Troubleshooting"
```

## Debugging Tips

- Run with debug flag: `hero docs -d -p .`
- Check the generated `sidebar.json`
- Verify the docs output in `~/hero/var/docusaurus/build/docs/`

## Error Messages

| Error                    | Solution                     |
| ------------------------ | ---------------------------- |
| "Page not found"         | Check page name spelling     |
| "Collection not found"   | Verify doctree configuration |
| "Link resolution failed" | Check link syntax            |

## Navigation

**Previous:** [Page 4: Advanced Features](test_collection:page4)

**Next:** [Page 6: Best Practices](test_collection:page6)

