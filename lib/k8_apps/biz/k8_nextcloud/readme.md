# k8_nextcloud



To get started

```v


import incubaid.herolib.installers.something.k8_nextcloud as k8_nextcloud_installer

heroscript:="
!!k8_nextcloud.configure name:'test'
 password: '1234'
 port: 7701

!!k8_nextcloud.start name:'test' reset:1 
"

k8_nextcloud_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= k8_nextcloud_installer.get()!
//installer.start(reset:true)!




```

## example heroscript


```hero
!!k8_nextcloud.configure
    homedir: '/home/user/k8_nextcloud'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```

