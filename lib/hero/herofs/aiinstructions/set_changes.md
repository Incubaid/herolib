```v
pub fn (mut self DBFsBlobMembership) set(mut o FsBlobMembership) ! {
```

becomes

```v
pub fn (mut self DBFsBlobMembership) set(o FsBlobMembership) FsBlobMembership! {
    ... the other code
    return o
}
```

we need to change each set in this module to be like this, then we need to make sure that _test.v programs use it the same way

see how we don't use the mut statement in set.

