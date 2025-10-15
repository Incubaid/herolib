# herorunner

To get started

```vlang


import incubaid.herolib.installers.something.herorunner as herorunner_installer

heroscript:="
!!herorunner.configure name:'test'
    password: '1234'
    port: 7701

!!herorunner.start name:'test' reset:1 
"

herorunner_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= herorunner_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!herorunner.configure
    homedir: '/home/user/herorunner'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```
