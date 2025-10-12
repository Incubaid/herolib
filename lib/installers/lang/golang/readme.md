# golang

To get started

```v


import incubaid.herolib.installers.lang.golang

mut installer:= golang.get()!

//will automatically do a destroy if the version changes, to make sure there are no left overs
installer.install()!

```
