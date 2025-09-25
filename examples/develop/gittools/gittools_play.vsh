#!/usr/bin/env -S v -n -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.develop.gittools
import os

heroscript := "

!!git.define
    coderoot:'/tmp/code' //when we overrule the location, the default is ~/code
    light:true //depth of git clone is 1
    log:true
    debug:false //give more error reporting
    offline:false //makes sure will not try to get to internet, but do all locally
    ssh_key_path:'' //if a specific ssh key is needed
    reload:false //if set then will remove cache and load full status, this is slow !

!!git.clone
    url:'https://github.com/vlang/v.git'
    light:true
    recursive:false

!!git.clone
    url:'https://github.com/incubaid/herolib.git'
    light:true
    recursive:false

!!git.list
    filter:'' //list all repositories
    status_update:false //don't check remote status (faster)

!!git.repo_action
    action:'pull'
    name:'v' //pull the V repository
    error_ignore:true //ignore errors if repo doesn't exist

!!git.repo_action
    action:'pull'
    name:'herolib' //pull the herolib repository
    error_ignore:true //ignore errors if repo doesn't exist

!!git.list
    filter:'' //list all repositories again to see updated status
    status_update:true //check remote status this time
"

gittools.play(heroscript: heroscript)!
