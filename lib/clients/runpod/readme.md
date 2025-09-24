# runpod



To get started

```v



import freeflowuniverse.herolib.clients. runpod

mut client:= runpod.get()!

client...




```

## example heroscript


```hero
!!runpod.configure
    secret: '...'
    host: 'localhost'
    port: 8888
```

**RunPod API Example**

This script demonstrates creating, stopping, starting, and terminating RunPod pods using the RunPod API. It creates both on-demand and spot pods.

**Requirements**

* Environment variable `RUNPOD_API_KEY` set with your RunPod API key

**How to Run**

- Find out our example in: examples/develop/runpod/runpod_example.vsh
