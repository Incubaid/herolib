# imagemagick



To get started

```v


import freeflowuniverse.herolib.installers.something.imagemagick as imagemagick_installer

heroscript:="
!!imagemagick.configure name:'test'
    password: '1234'
    port: 7701

!!imagemagick.start name:'test' reset:1 
"

imagemagick_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= imagemagick_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!imagemagick.configure
    homedir: '/home/user/imagemagick'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


