module models_ledger

import freeflowuniverse.herolib.hero.db

fn setup_test_db() !db.DB {
	mut mydb := db.new()!
	return mydb
}
