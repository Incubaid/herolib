# Installer - Herolib Module

### `herolib.install`

Installs the `hero` command-line tool.

**Example:**

```heroscript
!!herolib.install reset: true 
```

### `herolib.compile`

-   `git_pull` (bool): Pull the latest changes from the git repository. Default: `true`.
-   `git_reset` (bool): Reset the git repository. Default: `false`.
-   `reset` (bool): If true, reinstall. Default: `false`.

```heroscript
!!herolib.hero_compile git_reset:1 reset:1
```

### `herolib.uninstall`

```heroscript
!!herolib.uninstall
```
