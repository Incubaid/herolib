module ledger

import incubaid.herolib.hero.db
import json

pub struct ModelsFactory {
pub mut:
	db          &db.DB
	account     &DBAccount
	asset       &DBAsset
	dnszone     &DBDNSZone
	group       &DBGroup
	member      &DBMember
	notary      &DBNotary
	signature   &DBSignature
	transaction &DBTransaction
	user        &DBUser
	userkvs     &DBUserKVS
	userkvsitem &DBUserKVSItem
}

pub fn new_models_factory(mut database db.DB) !&ModelsFactory {
	mut factory := &ModelsFactory{
		db: database
	}

	factory.account = &DBAccount{
		db: database
	}
	factory.asset = &DBAsset{
		db: database
	}
	factory.dnszone = &DBDNSZone{
		db: database
	}
	factory.group = &DBGroup{
		db: database
	}
	factory.member = &DBMember{
		db: database
	}
	factory.notary = &DBNotary{
		db: database
	}
	factory.signature = &DBSignature{
		db: database
	}
	factory.transaction = &DBTransaction{
		db: database
	}
	factory.user = &DBUser{
		db: database
	}
	factory.userkvs = &DBUserKVS{
		db: database
	}
	factory.userkvsitem = &DBUserKVSItem{
		db: database
	}

	return factory
}
