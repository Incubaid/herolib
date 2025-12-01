# Docusaurus Link Resolution Test

This directory contains a comprehensive test for the herolib documentation linking mechanism.

## Structure

```
for_testing/
├── README.md                           # This file
├── collections/
│   └── test_collection/                # Markdown source files
│       ├── .collection                 # Collection metadata
│       ├── page1.md                    # Introduction
│       ├── page2.md                    # Basic Concepts
│       ├── page3.md                    # Configuration
│       ├── page4.md                    # Advanced Features
│       ├── page5.md                    # Troubleshooting
│       ├── page6.md                    # Best Practices
│       └── page7.md                    # Conclusion
└── ebooks/
    └── test_site/                      # Heroscript configuration
        ├── heroscriptall               # Master configuration (entry point)
        ├── config.heroscript           # Site configuration
        ├── pages.heroscript            # Page definitions
        └── docusaurus.heroscript       # Docusaurus settings
```

## What This Tests

1. **Link Resolution** - Each page contains links using the `[text](collection:page)` format
2. **Navigation Chain** - Pages link sequentially: 1 → 2 → 3 → 4 → 5 → 6 → 7
3. **Sidebar Generation** - All 7 pages should appear in the sidebar
4. **Category Support** - Pages are organized into categories (root, basics, advanced, reference)

## Running the Test

From the herolib root directory:

```bash
# Build herolib first
./cli/compile.vsh

# Run the test site
/Users/mahmoud/hero/bin/hero docs -d -p lib/web/docusaurus/for_testing/ebooks/test_site
```

## Expected Results

When the test runs successfully:

1. ✅ All 7 pages are generated in `~/hero/var/docusaurus/build/docs/`
2. ✅ Sidebar shows all pages organized by category
3. ✅ Clicking navigation links works (page1 → page2 → ... → page7)
4. ✅ No broken links or 404 errors
5. ✅ Back-links also work (e.g., page7 → page1)

## Link Syntax Being Tested

```markdown
[Next Page](test_collection:page2)
```

This should resolve to a proper Docusaurus link when the site is built.

## Verification

After running the test:

1. Open http://localhost:3000/test/ in your browser
2. Click through all navigation links from Page 1 to Page 7
3. Verify the back-link on Page 7 returns to Page 1
4. Check the sidebar displays all pages correctly

## Troubleshooting

If links don't resolve:

1. Check that the collection is registered in the doctree
2. Verify page names match (no typos)
3. Run with debug flag (`-d`) to see detailed output
4. Check `~/hero/var/docusaurus/build/docs/` for generated files

