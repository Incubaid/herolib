

the main data is in key value stor:

- each object has u32 id
- each object has u16 version (version of same data)
- each object has u16 schemaid (if schema changes)
- each object has tags u32 (to tag table)
- each object has a created_at timestamp
- each object has a updated_at timestamp
- each object has binary content (the data)
- each object has link to who can read/write/delete (lists of u32 per read/write/delete to group or user), link to security policy u32
- each object has a signature of the data by the user who created/updated it


- there are users & groups
- groups can have other groups and users inside
- users & groups are unique u32 as well in the DB, so no collision

this database does not know what the data is about, its agnostic to schema


now make the 4 structs which represent above

- data
- user
- group ([]u32) each links to user or group, name, description
- tags ([]string which gets a unique id, so its shorter to link to data object)
- securitypolicy (see below)

and encoding scheme using lib/data/encoder, we need encode/decode on the structs, so we have densest possible encoding

now we need the implementation details for each struct, including the fields and their types, as well as the encoding/decoding logic.

the outside is a server over openrpc which has

- set (userid:u32,  id:u32, data: Data, signature: string, tags:[]string) -> u32. (id can be 0 then its new, if existing we need to check if user can do it), tags will be recalculated based on []string (lower case, sorted list then md5 -> u32)
- get (userid:u32, id: u32, signedid: string) -> Data,Tags as []string
- exist (userid:u32, id: u32) -> bool //this we allow without signature
- delete (userid:u32, id: u32, signedid: string) -> bool
- list (userid:u32, signature: string, based on tags, schemaid, from creation/update and to creation/update), returns max 200 items -> u32


the interface is stateless, no previous connection known, based on signature the server can verify the user is allowed to perform the action

the backend database is redis (hsets and sets)


## signing implementation

the signing is in the same redis implemented, so no need to use vlang for that

```bash
# Generate an ephemeral signing keypair
redis-cli -p $PORT AGE GENSIGN
# Example output:
# 1) "<verify_pub_b64>"
# 2) "<sign_secret_b64>"

# Sign a message with the secret
redis-cli -p $PORT AGE SIGN "<sign_secret_b64>" "msg"
# → returns "<signature_b64>"

# Verify with the public key
redis-cli -p $PORT AGE VERIFY "<verify_pub_b64>" "msg" "<signature_b64>"
# → 1 (valid) or 0 (invalid)
```


versioning: when stored we don't have to worry about version the database will check if it exists, newest version and then update


## some of the base objects

```v
@[heap]
pub struct SecurityPolicy {
pub mut:
    id           u32
    read      []u32 //links to users & groups
    write     []u32 //links to users & groups
    delete    []u32 //links to users & groups
    public bool
}


@[heap]
pub struct Tags {
pub mut:
    id           u32
    names       []string //unique per id
    md5         string //of sorted names, to make easy to find unique id
}
```