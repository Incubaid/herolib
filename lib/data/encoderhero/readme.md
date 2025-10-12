# hero Encoder

```v

#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.data.encoderhero
import incubaid.herolib.core.base
import time

struct Person {
mut:
 name     string
 age      int = 20
 birthday time.Time
}

mut person := Person{
    name: 'Bob'
    birthday: time.now()
}
heroscript := encoderhero.encode[Person](person)!

println(heroscript)

person2 := encoderhero.decode[Person](heroscript)!

println(person2)

```
