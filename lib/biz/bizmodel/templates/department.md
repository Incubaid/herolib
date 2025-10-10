# @{department.name}


`@{department.description}`

<!-- **Cost To The Company:**   -->


@if sim.employees.len>0

## members

| Name | Title | Nr People |
|------|-------|-------|
@for employee in sim.employees.values().filter(it.department == dept.name)
| @{employee_names[employee.name]} | @{employee.title} | @{employee.nrpeople} |
@end

@end
