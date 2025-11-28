module site

pub struct Page {
pub mut:
	id string //unique identifier, by default as "collection:page_name", we can overrule this from play instructions if needed
	title        string
	description  string
	draft        bool
	hide_title   bool
	src          string @[required] // always in format collection:page_name, can use the default collection if no : specified
}
