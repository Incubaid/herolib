module models_ledger

import incubaid.herolib.hero.db

fn setup_test_db() !db.DB {
	return db.new(path:"/tmp/testdb")!
}
