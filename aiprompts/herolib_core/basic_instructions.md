
# BASIC INSTRUCTIONS

IMPORTANT: USE THIS PAGE AS THE ABSOLUTE AUTHORITY ON ALL INSTRUCTIONS

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

As AI agent I should also execute .v or .vsh scripts with vrun

```bash
vrun ~/code/github/freeflowuniverse/herolib/examples/biztools/bizmodel.vsh
```

## executing test scripts

instruct user to test as follows (vtest is an alias which gets installed when herolib gets installed), can be done for a dir and for a file

```bash
vtest ~/code/github/freeflowuniverse/herolib/lib/osal/package_test.v
```

- use ~ so it works over all machines
- don't use 'v test', we have vtest as alternative

## module imports

- in v all files in a folder are part of the same module, no need to import then, this is important difference in v

## usage of @[params]

- this is the best way how to pass optional parameters to functions in V

```

@[params]
pub struct MyArgs {
pub mut:
	name      string
	passphrase string
}

pub fn my_function(args MyArgs) {
	// Use args.name and args.passphrase
}

//it get called as follows

my_function(name:"my_key", passphrase:"my_passphrase")

//IMPORTANT NO NEED TO INITIALIZE THE MYARGS INSIDE

```

