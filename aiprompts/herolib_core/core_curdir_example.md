# Getting the Current Script's Path in Herolib/V Shell

can be used in any .v or .vsh script, easy to find content close to the script itself.

```v
#!/usr/bin/env vsh

const script_path = os.dir(@FILE) + '/scripts'
echo "Current scripts directory: ${script_directory}"

```
