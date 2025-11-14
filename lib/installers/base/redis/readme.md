# redis



To get started

```v


import incubaid.herolib.installers.something.redis as redis_installer

heroscript:="
!!redis.configure name:'test'
 password: '1234'
 port: 7701

!!redis.start name:'test' reset:1 
"

redis_installer.play(heroscript=heroscript)!

//or we can call the default and do a start with reset
//mut installer:= redis_installer.get()!
//installer.start(reset:true)!




```

## example heroscript


```hero
!!redis.configure
    homedir: '/home/user/redis'
    username: 'admin'
    password: 'secretpassword'
    title: 'Some Title'
    host: 'localhost'
    port: 8888

```

