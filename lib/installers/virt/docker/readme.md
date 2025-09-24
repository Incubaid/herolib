# docker

To get started

```v


import freeflowuniverse.herolib.installers.something.docker as docker_installer

heroscript:="
!!docker.configure name:'test'
    password: '1234'
    port: 7701

!!docker.start name:'test' reset:1 
"

docker_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= docker_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!docker.configure
    homedir: '/home/user/docker'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


