// lib/threefold/models_ledger/asset.v
module models_ledger

import incubaid.herolib.data.encoder
import incubaid.herolib.data.ourtime
import incubaid.herolib.hero.db
import json

// Asset represents a digital or physical item of value within the system.
@[heap]
pub struct Asset {
	db.Base
pub mut:
	address        string @[index; required] // The unique address or identifier for the asset.
	asset_type     string @[required]        // The type of the asset (e.g., 'token', 'nft').
	issuer         u32    @[required]        // The user ID of the issuer of the asset.
	supply         f64               // The total supply of the asset.
	decimals       u8                // The number of decimal places for the asset's value.
	is_frozen      bool              // Indicates if the asset is currently frozen and cannot be transferred.
	metadata       map[string]string // A map for storing arbitrary metadata as key-value pairs.
	administrators []u32             // A list of user IDs that are administrators for this asset.
	min_signatures u32               // The minimum number of signatures required for administrative actions.
}

pub struct DBAsset {
pub mut:
	db &db.DB @[skip; str: skip]
}

pub fn (self Asset) type_name() string {
	return 'asset'
}

pub fn (self Asset) description(methodname string) string {
	return match methodname {
		'set' { 'Create or update an asset. Returns the ID of the asset.' }
		'get' { 'Retrieve an asset by its unique ID.' }
		'delete' { 'Deletes an asset by its unique ID.' }
		'exist' { 'Checks if an asset with the given ID exists.' }
		'find' { 'Finds assets based on a filter expression.' }
		'count' { 'Counts the number of assets that match a filter expression.' }
		'list' { 'Lists all assets, optionally filtered and sorted.' }
		else { 'An asset represents a digital or physical item of value.' }
	}
}

pub fn (self Asset) example(methodname string) (string, string) {
	return match methodname {
		'set' { '{"asset": {"id": 1, "address": "G...", "asset_type": "token", "issuer": 1, "supply": 1000000.0, "decimals": 8}}', '1' }
		'get' { '{"id": 1}', '{"id": 1, "address": "G...", "asset_type": "token", "issuer": 1, "supply": 1000000.0, "decimals": 8}' }
		'delete' { '{"id": 1}', 'true' }
		'exist' { '{"id": 1}', 'true' }
		'find' { '{"filter": "address=\'G...\'"}', '[{"id": 1, "address": "G...", "asset_type": "token", "issuer": 1, "supply": 1000000.0, "decimals": 8}]' }
		'count' { '{"filter": "address=\'G...\'"}', '1' }
		'list' { '{}', '[{"id": 1, "address": "G...", "asset_type": "token", "issuer": 1, "supply": 1000000.0, "decimals": 8}]' }
		else { '{}', '{}' }
	}
}

pub fn (self Asset) dump(mut e encoder.Encoder) ! {
	e.add_string(self.address)
	e.add_string(self.asset_type)
	e.add_u32(self.issuer)
	e.add_f64(self.supply)
	e.add_u8(self.decimals)
	e.add_bool(self.is_frozen)

	e.add_map_string(self.metadata)
	e.add_list_u32(self.administrators)
	e.add_u32(self.min_signatures)
}

fn (mut self DBAsset) load(mut o Asset, mut e encoder.Decoder) ! {
	o.address = e.get_string()!
	o.asset_type = e.get_string()!
	o.issuer = e.get_u32()!
	o.supply = e.get_f64()!
	o.decimals = e.get_u8()!
	o.is_frozen = e.get_bool()!

	o.metadata = e.get_map_string()!
	o.administrators = e.get_list_u32()!
	o.min_signatures = e.get_u32()!
}

@[params]
pub struct AssetArg {
pub mut:
	name           string
	description    string
	address        string
	asset_type     string
	issuer         u32
	supply         f64
	decimals       u8
	is_frozen      bool
	metadata       map[string]string
	administrators []u32
	min_signatures u32
}

pub fn (mut self DBAsset) new(args AssetArg) !Asset {
	mut o := Asset{
		address:        args.address
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

pub fn (mut self DBAsset) delete(id u32) !bool {
	if !self.db.exists[Asset](id)! {
		return false
	}
	self.db.delete[Asset](id)!
	return true
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

@[params]
pub struct AssetListArg {
pub mut:
	filter       string
	asset_type   string
	is_frozen    bool = false
	filter_frozen bool = false
	issuer       u32
	filter_issuer bool = false
	limit        int = 20
	offset       int = 0
}

pub fn (mut self DBAsset) list(args AssetListArg) ![]Asset {
	mut all_assets := self.db.list[Asset]()!.map(self.get(it)!)
	mut filtered_assets := []Asset{}
	
	for asset in all_assets {
		// Filter by text in name or description
		if args.filter != '' && !asset.name.contains(args.filter) && 
		   !asset.description.contains(args.filter) && !asset.address.contains(args.filter) {
			continue
		}
		
		// Filter by asset_type
		if args.asset_type != '' && asset.asset_type != args.asset_type {
			continue
		}
		
		// Filter by is_frozen
		if args.filter_frozen && asset.is_frozen != args.is_frozen {
			continue
		}
		
		// Filter by issuer
		if args.filter_issuer && asset.issuer != args.issuer {
			continue
		}
		
		filtered_assets << asset
	}
	
	// Apply pagination
	mut start := args.offset
	if start >= filtered_assets.len {
		start = 0
	}
	
	mut limit := args.limit
	if limit > 100 {
		limit = 100
	}
	
	if start + limit > filtered_assets.len {
		limit = filtered_assets.len - start
	}
	
	if limit <= 0 {
		return []Asset{}
	}
	
	return if filtered_assets.len > 0 { filtered_assets[start..start+limit] } else { []Asset{} }
}

pub fn (mut self DBAsset) list_all() ![]Asset {
	return self.db.list[Asset]()!.map(self.get(it)!)
}

pub fn asset_handle(mut f ModelsFactory, rpcid int, servercontext map[string]string, userref UserRef, method string, params string) !Response {
	match method {
		'get' {
			id := db.decode_u32(params)!
			res := f.asset.get(id)!
			return new_response(rpcid, json.encode_pretty(res))
		}
		'set' {
			mut args := db.decode_generic[AssetArg](params)!
			mut o := f.asset.new(args)!
			if args.id != 0 {
				o.id = args.id
			}
			o = f.asset.set(o)!
			return new_response_int(rpcid, int(o.id))
		}
		'delete' {
			id := db.decode_u32(params)!
			success := f.asset.delete(id)!
			if success {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'exist' {
			id := db.decode_u32(params)!
			if f.asset.exist(id)! {
				return new_response_true(rpcid)
			} else {
				return new_response_false(rpcid)
			}
		}
		'list' {
			args := db.decode_generic_or_default[AssetListArg](params, AssetListArg{})!
			result := f.asset.list(args)!
			return new_response(rpcid, json.encode_pretty(result))
		}
		else {
			return new_error(
				rpcid: rpcid
				code: 32601
				message: 'Method ${method} not found on asset'
			)
		}
	}
}
