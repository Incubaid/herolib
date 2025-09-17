// lib/threefold/models_ledger/asset.v
module models_ledger

import freeflowuniverse.herolib.data.encoder
import freeflowuniverse.herolib.data.ourtime
import freeflowuniverse.herolib.hero.db

// Asset represents an asset in the financial system
@[heap]
pub struct Asset {
	db.Base
pub mut:
	address         string @[index]
	assetid         u32
	asset_type      string
	issuer          u32
	supply          f64
	decimals        u8
	is_frozen       bool
	metadata        map[string]string
	administrators  []u32
	min_signatures  u32
}

pub struct DBAsset {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Asset) type_name() string {
	return 'asset'
}

pub fn (self Asset) description(methodname string) string {
	match methodname {
		'set' {
			return 'Create or update an asset. Returns the ID of the asset.'
		}
		'get' {
			return 'Retrieve an asset by ID. Returns the asset object.'
		}
		'delete' {
			return 'Delete an asset by ID. Returns true if successful.'
		}
		'exist' {
			return 'Check if an asset exists by ID. Returns true or false.'
		}
		'list' {
			return 'List all assets. Returns an array of asset objects.'
		}
		else {
			return 'Asset management operations'
		}
	}
}

pub fn (self Asset) example(methodname string) (string, string) {
	match methodname {
		'set' {
			return '{"asset": {"address": "asset123", "assetid": 1, "asset_type": "token", "issuer": 1, "supply": 1000000.0, "decimals": 8}}', '1'
		}
		'get' {
			return '{"id": 1}', '{"address": "asset123", "assetid": 1, "asset_type": "token", "issuer": 1, "supply": 1000000.0, "decimals": 8}'
		}
		'delete' {
			return '{"id": 1}', 'true'
		}
		'exist' {
			return '{"id": 1}', 'true'
		}
		'list' {
			return '{}', '[{"address": "asset123", "assetid": 1, "asset_type": "token", "issuer": 1, "supply": 1000000.0, "decimals": 8}]'
		}
		else {
			return '{}', '{}'
		}
	}
}

pub fn (self Asset) dump(mut e encoder.Encoder) ! {
	e.add_string(self.address)
	e.add_u32(self.assetid)
	e.add_string(self.asset_type)
	e.add_u32(self.issuer)
	e.add_f64(self.supply)
	e.add_u8(self.decimals)
	e.add_bool(self.is_frozen)
	
	// metadata map
	e.add_int(self.metadata.len)
	for key, value in self.metadata {
		e.add_string(key)
		e.add_string(value)
	}
	
	e.add_list_u32(self.administrators)
	e.add_u32(self.min_signatures)
}

fn (mut self DBAsset) load(mut o Asset, mut e encoder.Decoder) ! {
	o.address = e.get_string()!
	o.assetid = e.get_u32()!
	o.asset_type = e.get_string()!
	o.issuer = e.get_u32()!
	o.supply = e.get_f64()!
	o.decimals = e.get_u8()!
	o.is_frozen = e.get_bool()!
	
	// metadata map
	metadata_len := e.get_int()!
	o.metadata = map[string]string{}
	for _ in 0 .. metadata_len {
		key := e.get_string()!
		value := e.get_string()!
		o.metadata[key] = value
	}
	
	o.administrators = e.get_list_u32()!
	o.min_signatures = e.get_u32()!
}

@[params]
pub struct AssetArg {
pub mut:
	name            string
	description     string
	address         string
	assetid         u32
	asset_type      string
	issuer          u32
	supply          f64
	decimals        u8
	is_frozen       bool
	metadata        map[string]string
	administrators  []u32
	min_signatures  u32
}

pub fn (mut self DBAsset) new(args AssetArg) !Asset {
	mut o := Asset{
		address:        args.address
		assetid:        args.assetid
		asset_type:     args.asset_type
		issuer:         args.issuer
		supply:         args.supply
		decimals:       args.decimals
		is_frozen:      args.is_frozen
		metadata:       args.metadata
		administrators: args.administrators
		min_signatures: args.min_signatures
	}

	o.name = args.name
	o.description = args.description
	o.updated_at = ourtime.now().unix()

	return o
}

pub fn (mut self DBAsset) set(o Asset) !Asset {
	return self.db.set[Asset](o)!
}

pub fn (mut self DBAsset) delete(id u32) ! {
	self.db.delete[Asset](id)!
}

pub fn (mut self DBAsset) exist(id u32) !bool {
	return self.db.exists[Asset](id)!
}

pub fn (mut self DBAsset) get(id u32) !Asset {
	mut o, data := self.db.get_data[Asset](id)!
	mut e_decoder := encoder.decoder_new(data)
	self.load(mut o, mut e_decoder)!
	return o
}

pub fn (mut self DBAsset) list() ![]Asset {
	return self.db.list[Asset]()!.map(self.get(it)!)
}