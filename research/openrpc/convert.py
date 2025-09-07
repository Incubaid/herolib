
import json
from jinja2 import Template

# load OpenRPC spec
with open("openrpc.json") as f:
    spec = json.load(f)

# load template
with open("openrpc_to_md.j2") as f:
    tmpl = Template(f.read())

# render markdown
output = tmpl.render(spec=spec)

print(output)
