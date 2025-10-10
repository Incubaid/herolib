implement lib/hero/heroserver

see aiprompts/v_core/veb for how servers are done and also see examples/hero/herorpc/herorpc_example.vsh how we start the server  in an example
and the implementation of the example of how webserver is see lib/schemas/openrpc/controller_http.v

specs for the heroserver

- a factory (without globals) creates a server, based on chosen port
- the server does basic authentication and has
  - register method: pubkey
  - authreq: pubkey, it returns a unique key (hashed md5 of pubkey + something random). (is a request for authentication)
  - auth: the user who wants access signs the unique key from authreq with , and sends the signature to the server, who then knows for sure I know this user, we return as sessionkey
- all consequent requests need to use this sessionkey, so the server knows who is doing the requests
- the server serves the openrpc api behind api/$handlertype/... the $handlertype is per handler type, so we can register more than 1 openrpc hander
- the server serves an html endpoint for doc/$handlertype/

for the doc (html endpoint)

- use bootstrap from cdn
  - <https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css>
  - <https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.min.js>
  - <https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js>
- create an html template in lib/hero/heroserver/template/doc.html (template for v language)
  - the template uses the openrpc spec obj comes from lib/schemas/openrpc and  lib/schemas/jsonrpc for the schema's
  - so first fo the spec decode to the object from schemas/openrpc then use this obj to populate the template
  - in the template make a header 1 for each rootobject e.g. calendar, then dense show the methods with directly in the method a dense representation of the params and return
  - each object has a method to show description and example (returns string)
    - e.g. fn (self Comment) description(methodname string) string, which returns the return for the specified method, if not method specified then show description for the object in this case Comment
    - e.g. fn (self Comment) example(methodname string) (string, string) wich returns example call and example return (hense double return)
  - the purpose is to have a very nice documentation done per object so we know what the object does, and how to use it

make clear instructions what code needs to be written and which steps are needed
we are in architecture mode

other requirements

- for encryption/signing primitives use instructions from lib/hero/crypt/readme.md, ONLY USE THESE METHODS NO OTHER VLANG METHODS

