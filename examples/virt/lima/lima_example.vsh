#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

// import freeflowuniverse.herolib.virt.lima
import freeflowuniverse.herolib.core.texttools
import freeflowuniverse.herolib.ui.console
import freeflowuniverse.herolib.installers.virt.lima as limainstaller
import os

mut i:=limainstaller.get(create:true)!
i.install(reset:true)!

// mut virtmanager := lima.new()!

// virtmanager.vm_delete_all()!

// // virtmanager.vm_new(reset:true,template:.alpine,name:'alpine',install_hero:false)!

// // virtmanager.vm_new(reset:true,template:.arch,name:'arch',install_hero:true)!

// virtmanager.vm_new(reset: true, template: .ubuntucloud, name: 'hero', install_hero: false)!
// mut vm := virtmanager.vm_get('hero')!

// println(vm)

// // vm.install_hero()!

// // console.print_debug_title("MYVM", vm.str())
