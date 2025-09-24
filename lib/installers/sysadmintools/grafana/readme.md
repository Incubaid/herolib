# grafana



To get started

```v


import freeflowuniverse.herolib.installers.something.grafana as grafana_installer

heroscript:="
!!grafana.configure name:'test'
    password: '1234'
    port: 7701

!!grafana.start name:'test' reset:1 
"

grafana_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= grafana_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!grafana.configure
    homedir: '/home/user/grafana'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


