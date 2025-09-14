
## http based RPC server


```bash

curl -s http://localhost:9933/ \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "comment_set",
    "params": {
      "comment": "Hello world!",
      "parent": 0,
      "author": 42
    },
    "id": 1
  }' | jq .

{
  "jsonrpc": "2.0",
  "result": "46",
  "id": 1
}

```

## unix socket based RPC server

```bash
# to test the discover function, this returns the openrpc specification:
echo '{"jsonrpc":"2.0","method":"rpc.discover","params":[],"id":1}' | nc -U /tmp/heromodels

# to test interactively:

nc -U /tmp/heromodels

# then e.g. paste following in

{"jsonrpc":"2.0","method":"comment_set","params":{"comment":"Hello world!","parent":0,"author":42},"id":1}

needs to be on one line for openrpc to work

```

see lib/hero/heromodels/rpc/openrpc.json for the full openrpc specification


