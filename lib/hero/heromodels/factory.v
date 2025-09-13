module heromodels

import freeflowuniverse.herolib.hero.db

pub struct ModelsFactory {
pub mut:
	comments DBComments
}

pub fn new() !ModelsFactory {
	mut mydb := db.new()!
	return ModelsFactory{
		comments: DBComments{
			db: &mydb
		}
	}
}
