# cometbft



To get started

```v


import freeflowuniverse.herolib.installers.db.cometbft as cometbft_installer

heroscript:="
!!cometbft.configure name:'test'
    password: '1234'
    port: 7701

!!cometbft.start name:'test' reset:1 
"

cometbft_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= cometbft_installer.get()!
//installer.start(reset:true)!




```

## example heroscript

```hero
!!cometbft.configure
    homedir: '/home/user/cometbft'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```


