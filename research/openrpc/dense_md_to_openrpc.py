import re
import yaml
import json
import requests
from collections import defaultdict
from jsonschema import validate, Draft7Validator

# --- Load OpenRPC meta-schema ---
def load_openrpc_schema():
    url = "https://open-rpc.github.io/meta-schema.json"
    resp = requests.get(url)
    resp.raise_for_status()
    return resp.json()

OPENRPC_SCHEMA = load_openrpc_schema()

def parse_dense_markdown(md_text: str):
    methods = []
    schemas = {}

    # Split into sections
    sections = re.split(r"^# ", md_text, flags=re.M)
    secmap = {}
    for sec in sections:
        if not sec.strip():
            continue
        title, _, body = sec.partition("\n")
        secmap[title.strip()] = body.strip()

    # --- Methods ---
    if "Methods" in secmap:
        method_blocks = re.split(r"^## ", secmap["Methods"], flags=re.M)
        for block in method_blocks:
            if not block.strip():
                continue
            name, _, body = block.partition("\n")
            method = {"name": name.strip(), "params": [], "result": {}}

            lines = [l.rstrip() for l in body.splitlines() if l.strip()]

            # description before **Params**
            desc_lines = []
            i = 0
            while i < len(lines) and not lines[i].startswith("**Params**"):
                desc_lines.append(lines[i])
                i += 1
            method["description"] = " ".join(desc_lines).strip()

            # Params
            if "**Params**" in lines:
                pi = lines.index("**Params**") + 1
                while pi < len(lines) and not lines[pi].startswith("**Result**"):
                    line = lines[pi].lstrip("-").strip()
                    if line and not line.lower().startswith("none"):
                        pname, _, pdesc = line.partition("(")
                        pname = pname.strip()
                        ptype = pdesc.split(",")[0].replace(")", "").strip() if pdesc else "object"
                        required = "required" in line
                        param = {
                            "name": pname,
                            "required": required,
                            "schema": {"type": map_type(ptype)}
                        }
                        method["params"].append(param)
                    pi += 1

            # Result
            if "**Result**" in lines:
                ri = lines.index("**Result**") + 1
                if ri < len(lines):
                    rline = lines[ri].lstrip("-").strip()
                    rname, _, rtype = rline.partition(":")
                    rname = rname.strip()
                    rtype = rtype.strip()
                    schema = parse_result_type(rtype)
                    method["result"] = {"name": rname, "schema": schema}

            methods.append(method)

    # --- Schemas ---
    if "Schemas" in secmap:
        schema_blocks = re.split(r"^## ", secmap["Schemas"], flags=re.M)
        for block in schema_blocks:
            if not block.strip():
                continue
            name, _, body = block.partition("\n")
            lines = body.splitlines()
            code_block = []
            req_fields = []
            in_yaml = False
            for l in lines:
                if l.strip().startswith("```yaml"):
                    in_yaml = True
                    continue
                elif l.strip().startswith("```"):
                    in_yaml = False
                    continue
                if in_yaml:
                    code_block.append(l)
                if l.strip().startswith("*Required:"):
                    req_fields = [x.strip() for x in l.split(":")[1].split(",")]
            if code_block:
                schema_def = yaml.safe_load("\n".join(code_block))
                props = {}
                for fname, ftype in schema_def.items():
                    if isinstance(ftype, str):
                        base = ftype.split("#")[0].strip()
                        desc = ftype.split("#")[1].strip() if "#" in ftype else None
                        props[fname] = {"type": map_type(base)}
                        if desc:
                            props[fname]["description"] = desc
                schemas[name.strip()] = {
                    "type": "object",
                    "properties": props,
                    "required": req_fields
                }

    spec = {"openrpc": "1.0.0", "methods": methods, "components": {"schemas": schemas}}

    # --- Validate against OpenRPC schema ---
    validator = Draft7Validator(OPENRPC_SCHEMA)
    errors = sorted(validator.iter_errors(spec), key=lambda e: e.path)
    if errors:
        for err in errors:
            print(f"❌ Validation error at {list(err.path)}: {err.message}")
        raise ValueError("Generated spec is not valid OpenRPC")
    else:
        print("✅ Spec is valid OpenRPC")

    return spec

# --- Helpers ---
def map_type(t):
    mapping = {"int": "integer", "str": "string", "bool": "boolean", "object": "object"}
    return mapping.get(t, t)

def parse_result_type(rtype):
    if "|" in rtype:
        oneofs = []
        for variant in rtype.split("|"):
            v = variant.strip()
            if v.startswith("[") and v.endswith("]"):
                oneofs.append({"type": "array", "items": {"$ref": f"#/components/schemas/{v[1:-1]}"}})
            else:
                oneofs.append({"$ref": f"#/components/schemas/{v}"})
        return {"oneOf": oneofs}
    elif rtype.startswith("[") and rtype.endswith("]"):
        return {"type": "array", "items": {"type": map_type(rtype[1:-1])}}
    elif rtype in ["int", "str", "bool", "object"]:
        return {"type": map_type(rtype)}
    else:
        return {"$ref": f"#/components/schemas/{rtype}"}


# --- Example usage ---
if __name__ == "__main__":
    with open("dense.md") as f:
        md = f.read()

    spec = parse_dense_markdown(md)

    with open("openrpc.json", "w") as f:
        json.dump(spec, f, indent=2)
