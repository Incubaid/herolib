#!/usr/bin/env -S v -n -w -cg -gc none -no-retry-compilation -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.biz.bizmodel
import freeflowuniverse.herolib.core.playbook
import os

heroscript := "

!!bizmodel.hr_params bizname:'test' avg_monthly_cost:'4000USD' avg_indexation:'5%'

!!bizmodel.department_define bizname:'test' 
    name:'engineering'
    descr:'Software Development Department'
    title:'Engineering Division'

//need to define some revenue because otherwise can't see how HR relates to it
!!bizmodel.revenue_define bizname:'test' name:'oem1' extrapolate:1
    descr:'OEM Deals'  revenue:'0:1000000,60:10000000' 
    cogs_percent: '0:20%'

!!bizmodel.employee_define bizname:'test'  name:'junior_engineer'
    descr:'Junior Engineer'
    nrpeople:'0:10,60:50'
    cost:'4000USD' indexation:'5%'
    department:'engineering'
    cost_percent_revenue:'20%'

!!bizmodel.employee_define bizname:'test' name:'marketing_group'
    descr:'Marketing Team'
    cost_percent_revenue:'2%'

!!bizmodel.employee_define bizname:'test'
    name:'ourclo'
    descr:'CLO'
    cost:'10000EUR'
    indexation:'5%'

"

// Create a new playbook with the heroscript text
mut pb := playbook.new(text: heroscript)!

// Play the bizmodel actions
bizmodel.play(mut pb)!

// Get the bizmodel and print it
mut bm := bizmodel.get('test')!

bm.sheet.pprint(nr_columns: 20)!
