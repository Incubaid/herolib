module meta

struct Category {
pub mut:
	path        string // e.g. Operations/Daily (means 2 levels deep, first level is Operations)
	collapsible bool = true
	collapsed   bool
}
