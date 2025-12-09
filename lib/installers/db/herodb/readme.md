# herodb

HeroDB installer for herolib.

## To get started

```v
import incubaid.herolib.installers.db.herodb

heroscript := "
!!herodb.configure name:'test'
    adminsecret: 'mysecret1234'
    port: 5555
    path: '/var/lib/herodb'

!!herodb.start name:'test' reset:true
"

mut plbook := playbook.new(text: heroscript)!
herodb.play(mut plbook)!

// or we can call the installer directly
// mut installer := herodb.get(name: 'test')!
// installer.start(reset: true)!
```

## Example heroscript

```hero
!!herodb.configure
    name: 'default'
    adminsecret: 'secretpassword'
    host: 'localhost'
    port: 5555
    path: '/var/lib/herodb'
    rpc_socket: '/var/run/herodb/admin.sock'

!!herodb.start reset:true
```

