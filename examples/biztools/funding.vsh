#!/usr/bin/env -S v -n -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.biz.bizmodel
import freeflowuniverse.herolib.core.playbook
import os

heroscript := "

!!bizmodel.funding_define bizname:'test' name:'seed_capital'
    descr:'Initial Seed Capital Investment'
    investment:'0:500000,12:200000'
    type:'capital'

!!bizmodel.funding_define bizname:'test' name:'bank_loan'
    descr:'Bank Loan for Expansion'
    investment:'6:100000,18:50000'
    type:'loan'

"

// Create a new playbook with the heroscript text
mut pb := playbook.new(text: heroscript)!

// Play the bizmodel actions
bizmodel.play(mut pb)!

// Get the bizmodel and print it
mut bm := bizmodel.get('test')!

bm.sheet.pprint(nr_columns: 20)!
