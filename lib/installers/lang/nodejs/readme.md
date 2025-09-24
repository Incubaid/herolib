# nodejs



To get started

```v


import freeflowuniverse.herolib.installers.something.nodejs as nodejs_installer

heroscript:="
!!nodejs.configure name:'test'
    password: '1234'
    port: 7701

!!nodejs.start name:'test' reset:1 
"

nodejs_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= nodejs_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!nodejs.configure
    homedir: '/home/user/nodejs'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


