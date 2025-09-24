# griddriver

To use the installer:

```v
import freeflowuniverse.herolib.installers.threefold.griddriver

fn main() {
	mut installer := griddriver.get()!
	installer.install()!
}
```

## example heroscript

```hero
!!griddriver.install
    homedir: '/home/user/griddriver'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```
