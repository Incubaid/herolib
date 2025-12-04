# Building Hero for release

Generally speaking, our scripts and docs for building hero produce non portable binaries for Linux. While that's fine for development purposes, statically linked binaries are much more convenient for releases and distribution.

The release workflow here creates a static binary for Linux using an Alpine container. A few notes follow about how that's done.

## Static builds in vlang

Since V compiles to C in our case, we are really concerned with how to produce static C builds. The V project provides [some guidance](https://github.com/vlang/v?tab=readme-ov-file#docker-with-alpinemusl) on using an Alpine container and passing `-cflags -static` to the V compiler.

That's fine for some projects. Hero has a dependency on the `libpq` C library for Postgres functionality, however, and this creates a complication.

## Static linking libpq

In order to create a static build of hero on Alpine, we need to install some additional packages:

* openssl-libs-static
* postgresql-dev

The full `apk` command to prepare the container for building looks like this:

```bash
apk add --no-cache bash git build-base openssl-dev libpq-dev postgresql-dev openssl-libs-static
```

Then we also need to instruct the C compiler to link against the Postgres static shared libraries. Here's the build command:

```bash
v -w -d use_openssl -enable-globals -cc gcc -cflags -static -ldflags "-lpgcommon_shlib -lpgport_shlib" cli/hero.v
```

Note that gcc is also the preferred compiler for static builds.
