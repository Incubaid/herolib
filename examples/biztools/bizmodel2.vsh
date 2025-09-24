#!/usr/bin/env -S v -n -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.biz.bizmodel
import freeflowuniverse.herolib.core.playbook
import os

heroscript := "

!!bizmodel.revenue_define bizname:'test' name:'nodes'
    descr:'Node Sales'  
    nr_sold: '0:10,20:10'
    revenue_item_setup:'0:1000,20:1200' revenue_item_setup_delay:1 
    revenue_item_monthly:'0:5' revenue_item_monthly_delay:1        
    cogs_item_monthly_rev_perc: '40%'
    cogs_item_delay:1
    cogs_item_setup_rev_perc: '80%'
    //revenue_item_monthly_perc:'3%'
"

// Create a new playbook with the heroscript text
mut pb := playbook.new(text: heroscript)!

// Play the bizmodel actions
bizmodel.play(mut pb)!

// Get the bizmodel and print it
mut bm := bizmodel.get('test')!

bm.sheet.pprint(nr_columns: 30)!
