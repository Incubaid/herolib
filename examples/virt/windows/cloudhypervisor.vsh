#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.installers.virt.cloudhypervisor as cloudhypervisor_installer
import incubaid.herolib.virt.cloudhypervisor
import incubaid.herolib.core.texttools
import incubaid.herolib.ui.console
import os

mut ci := cloudhypervisor_installer.get()!
ci.install(reset: true)!

// mut vmm:=cloudhypervisor.new()!

// virtmanager.vm_delete_all()!
// virtmanager.vm_new(reset:true,template:.alpine,name:'alpine',install_hero:true)!
// virtmanager.vm_new(reset:true,template:.ubuntu,name:'ubuntu',install_hero:true)!
// vmm.vm_new(reset:true,template:.arch,name:'arch',install_hero:true)!

// mut vm:=virtmanager.vm_get('ubuntu')!
// vm.install_hero()!

// console.print_debug_title("MYVM", vm.str())
