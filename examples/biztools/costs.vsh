#!/usr/bin/env -S v -n -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.biz.bizmodel
import freeflowuniverse.herolib.core.playbook
import os

heroscript := "

//need to define some revenue because otherwise can't see how HR relates to it
!!bizmodel.revenue_define bizname:'test' name:'oem1' extrapolate:1
    descr:'OEM Deals'  revenue:'0:1000000,60:10000000' 
    cogs_percent: '0:20%'

!!bizmodel.department_define bizname:'test' name:'marketing'
    descr:'Marketing Department'

!!bizmodel.department_define bizname:'test' name:'engineering'
    descr:'Engineering Department'

!!bizmodel.costcenter_define bizname:'test' name:'marketing_cc'
    descr:'Marketing Cost Center'
    department:'marketing'

!!bizmodel.cost_define bizname:'test' name:'office_rent'
    descr:'Office Rent'
    cost:'8000USD'
    indexation:'3%'
    costcenter:'marketing_cc'
    cost_percent_revenue:'0.5%'

!!bizmodel.cost_define bizname:'test' name:'travel'
    descr:'Office Rent'
    cost:'2:5000USD' //start month 3
    costcenter:'marketing_cc'

!!bizmodel.cost_define bizname:'test' name:'triptomoon'
    descr:'Office Rent'
    cost:'10:500000USD' extrapolate:0 //this means we do a one off cost in this case month 11
    costcenter:'marketing_cc'


// !!bizmodel.cost_define bizname:'test' name:'software_licenses'
//     descr:'Annual Software Licenses'
//     cost:'0:10000 10:EUR:20kCHF,12:5000USD'
//     department:'engineering'

"

// Create a new playbook with the heroscript text
mut pb := playbook.new(text: heroscript)!

// Play the bizmodel actions
bizmodel.play(mut pb)!

// Get the bizmodel and print it
mut bm := bizmodel.get('test')!

bm.sheet.pprint(nr_columns: 20)!
