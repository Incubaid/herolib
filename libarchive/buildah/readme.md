
# Herocontainers

Tools to work with containers

```go
#!/usr/bin/env -S  v -n -cg -w -enable-globals run

import freeflowuniverse.herolib.virt.herocontainers
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.builder

//interative means will ask for login/passwd

console.print_header("BUILDAH Demo.")

//if herocompile on, then will forced compile hero, which might be needed in debug mode for hero 
// to execute hero scripts inside build container
mut factory:=herocontainers.new(herocompile=true)!
//mut b:=factory.builder_new(name:"test")!

//create 
factory.builderv_create()!

//get the container
//mut b2:=factory.builder_get("builderv")!
//b2.shell()!


```

## buildah tricks

```bash
#find the containers as have been build, these are the active ones you can work with
buildah ls
#see the images
buildah images
```

result is something like


```bash
CONTAINER ID  BUILDER  IMAGE ID     IMAGE NAME                       CONTAINER NAME
a9946633d4e7     *                  scratch                          base
86ff0deb00bf     *     4feda76296d6 localhost/builder:latest         base_go_rust
```

some tricks

```bash
#run interactive in one (here we chose the builderv one)
buildah run --terminal --env TERM=xterm base /bin/bash
#or
buildah run --terminal --env TERM=xterm default /bin/bash
#or
buildah run --terminal --env TERM=xterm base_go_rust /bin/bash

```

to check inside the container about diskusage

```bash
apt install ncdu
ncdu
```

## create container


```go
import freeflowuniverse.herolib.virt.herocontainers
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.builder

//interative means will ask for login/passwd

console.print_header("Get a container.")

mut e:=herocontainers.new()!

//info see https://docs.podman.io/en/latest/markdown/podman-run.1.html

mut c:=e.container_create(
    name: 'mycontainer'
    image_repo: 'ubuntu'
    // Resource limits
    memory: '1g'
    cpus: 0.5
    // Network config
    network: 'bridge'
    network_aliases: ['myapp', 'api']
    // DNS config
    dns_servers: ['8.8.8.8', '8.8.4.4']
    dns_search: ['example.com']
    interactive: true  // Keep STDIN open
    mounts: [
        'type=bind,src=/data,dst=/container/data,ro=true'
    ]
    volumes: [
        '/config:/etc/myapp:ro'
    ]
    published_ports: [
        '127.0.0.1:8080:80'
    ]    
)!




```


## future

should make this module compatible with https://github.com/containerd/nerdctl