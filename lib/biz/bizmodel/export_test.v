module bizmodel

import os
import incubaid.herolib.web.docusaurus

const bizmodel_name = 'test'
const export_path = os.join_path(os.dir(@FILE), 'exampledata')

pub fn test_export_report() ! {
	model := getset(bizmodel_name)!
	model.export_report(Report{
		title: 'My Business Model'
	},
		path: export_path
	)!
}
