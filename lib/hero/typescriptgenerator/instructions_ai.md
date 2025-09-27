check lib/hero/heromodels/openrpc.json

can we create a a module in hero/typescriptgenerator

which takes an openrpc.json and creates an intermediate easy to use model (like we did for heroserver)
and then use this model to generate a typescript client

we should have a separate file per root model

API Endpoint: http://localhost:8086/api/heromodels
is here and its all as http posts

example

All API endpoints use JSON-RPC 2.0 format. Here's a basic example:

curl -X POST http://localhost:8086/api/[handler_name] \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "method_name",
    "params": {
      "param1": "value1",
      "param2": "value2"
    },
    "id": 1
  }'

