# module pbkdf2


## Contents
- [key](#key)

## key
```v
fn key(password []u8, salt []u8, count int, key_length int, h hash.Hash) ![]u8
```

key derives a key from the password, salt and iteration count example pbkdf2.key('test'.bytes(), '123456'.bytes(), 1000, 64, sha512.new())

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:18:17
