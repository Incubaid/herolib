# module ftp


## Contents
- [new](#new)
- [FTP](#FTP)
  - [connect](#connect)
  - [login](#login)
  - [close](#close)
  - [pwd](#pwd)
  - [cd](#cd)
  - [dir](#dir)
  - [get](#get)

## new
```v
fn new() FTP
```

new returns an `FTP` instance.

[[Return to contents]](#Contents)

## FTP
## connect
```v
fn (mut zftp FTP) connect(oaddress string) !bool
```

connect establishes an FTP connection to the host at `oaddress` (ip:port).

[[Return to contents]](#Contents)

## login
```v
fn (mut zftp FTP) login(user string, passwd string) !bool
```

login sends the "USER `user`" and "PASS `passwd`" commands to the remote host.

[[Return to contents]](#Contents)

## close
```v
fn (mut zftp FTP) close() !
```

close closes the FTP connection.

[[Return to contents]](#Contents)

## pwd
```v
fn (mut zftp FTP) pwd() !string
```

pwd returns the current working directory on the remote host for the logged in user.

[[Return to contents]](#Contents)

## cd
```v
fn (mut zftp FTP) cd(dir string) !
```

cd changes the current working directory to the specified remote directory `dir`.

[[Return to contents]](#Contents)

## dir
```v
fn (mut zftp FTP) dir() ![]string
```

dir returns a list of the files in the current working directory.

[[Return to contents]](#Contents)

## get
```v
fn (mut zftp FTP) get(file string) ![]u8
```

get retrieves `file` from the remote host.

[[Return to contents]](#Contents)

#### Powered by vdoc. Generated on: 2 Sep 2025 07:16:36
