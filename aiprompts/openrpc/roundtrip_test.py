import json
import sys
from dense_md_to_openrpc import parse_dense_markdown
from jinja2 import Template

# Load the Jinja2 template for JSON → Markdown
with open("openrpc_to_md.j2") as f:
    md_template = Template(f.read())

def roundtrip(md_path: str):
    print(f"🔄 Round-trip test for {md_path}")

    # 1. Markdown → JSON
    with open(md_path) as f:
        md_text = f.read()
    spec1 = parse_dense_markdown(md_text)
    print("✅ Step 1: Markdown → JSON")

    # 2. Validate already happens inside parse_dense_markdown

    # 3. JSON → Markdown
    md2 = md_template.render(spec=spec1)
    print("✅ Step 2: JSON → Markdown")

    # 4. Markdown → JSON again
    spec2 = parse_dense_markdown(md2)
    print("✅ Step 3: Markdown → JSON (again)")

    # 5. Compare results
    spec1_str = json.dumps(spec1, sort_keys=True, indent=2)
    spec2_str = json.dumps(spec2, sort_keys=True, indent=2)

    if spec1_str == spec2_str:
        print("🎉 Round-trip is stable! (JSON1 == JSON2)")
    else:
        print("⚠️ Round-trip mismatch!")
        with open("spec1.json", "w") as f:
            f.write(spec1_str)
        with open("spec2.json", "w") as f:
            f.write(spec2_str)
        with open("roundtrip_diff.md", "w") as f:
            f.write("## Original JSON (Markdown → JSON)\n```json\n")
            f.write(spec1_str + "\n```\n")
            f.write("\n## After Round-trip (JSON → Markdown → JSON)\n```json\n")
            f.write(spec2_str + "\n```\n")
        print("👉 Differences written to spec1.json, spec2.json, and roundtrip_diff.md")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python roundtrip_test.py dense.md")
        sys.exit(1)

    roundtrip(sys.argv[1])
