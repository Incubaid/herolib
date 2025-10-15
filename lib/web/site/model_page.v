module site

pub struct Page {
pub mut:
	name string
	title       string
	description string
	draft       bool
	position    int
	hide_title  bool
	src         string @[required] // always in format collection:page_name, can use the default collection if no : specified
	path        string @[required] //is without the page name, so just the path to the folder where the page is in
	section_name string
	title_nr    int
	slug        string
}
