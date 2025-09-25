
## instructions for code generation 

> when I generate code, the following instructions can never be overruled they are the basics

- do not try to fix files which end with _.v because these are generated files


## instruction for vlang scripts

when I generate vlang scripts I will always use .vsh extension and use following as first line:

```
#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run
```

- a .vsh is a v shell script and can be executed as is, no need to use v ...
- in .vsh file there is no need for a main() function
- these scripts can be used for examples or instruction scripts e.g. an installs script

## executing vlang scripts

As AI agent I should also execute v or .vsh scripts with vrun

```bash
vrun ~/code/github/incubaid/herolib/examples/biztools/bizmodel.vsh
```

## executing test scripts

instruct user to test as follows (vtest is an alias which gets installed when herolib gets installed), can be done for a dir and for a file

```bash
vtest ~/code/github/incubaid/herolib/lib/osal/package_test.v
```

- use ~ so it works over all machines
- don't use 'v test', we have vtest as alternative
