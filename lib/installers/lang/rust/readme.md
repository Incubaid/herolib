# rust



To get started

```v


import freeflowuniverse.herolib.installers.something.rust as rust_installer

heroscript:="
!!rust.configure name:'test'
    password: '1234'
    port: 7701

!!rust.start name:'test' reset:1 
"

rust_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= rust_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!rust.configure
    homedir: '/home/user/rust'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


