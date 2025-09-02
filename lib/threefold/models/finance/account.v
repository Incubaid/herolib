module finance

// Account represents a financial account owned by a user
@[heap]
pub struct Account {
pub mut:
	id          u32      // Unique account ID
	name        string   // Internal name of the account for the user
	user_id     u32      // User ID of the owner of the account
	description string   // Optional description of the account
	ledger      string   // Describes the ledger/blockchain where the account is located
	address     string   // Address of the account on the blockchain
	pubkey      string   // Public key
	assets      []u32    // List of asset IDs in this account
	created_at  u64      // Creation timestamp
	updated_at  u64      // Last update timestamp
}

// new creates a new Account with default values
pub fn Account.new() Account {
	return Account{
		id: 0
		name: ''
		user_id: 0
		description: ''
		ledger: ''
		address: ''
		pubkey: ''
		assets: []
		created_at: 0
		updated_at: 0
	}
}

// name sets the name of the account (builder pattern)
pub fn (mut a Account) name(name string) Account {
	a.name = name
	return a
}

// user_id sets the user ID of the account owner (builder pattern)
pub fn (mut a Account) user_id(user_id u32) Account {
	a.user_id = user_id
	return a
}

// description sets the description of the account (builder pattern)
pub fn (mut a Account) description(description string) Account {
	a.description = description
	return a
}

// ledger sets the ledger/blockchain where the account is located (builder pattern)
pub fn (mut a Account) ledger(ledger string) Account {
	a.ledger = ledger
	return a
}

// address sets the address of the account on the blockchain (builder pattern)
pub fn (mut a Account) address(address string) Account {
	a.address = address
	return a
}

// pubkey sets the public key of the account (builder pattern)
pub fn (mut a Account) pubkey(pubkey string) Account {
	a.pubkey = pubkey
	return a
}

// add_asset adds an asset to the account (builder pattern)
pub fn (mut a Account) add_asset(asset_id u32) Account {
	a.assets << asset_id
	return a
}

// total_value gets the total value of all assets in the account
// TODO: implement actual calculation based on asset values
pub fn (a Account) total_value() f64 {
	return 0.0
}

// find_asset_by_name finds an asset by name
// TODO: implement when asset lookup is available
pub fn (a Account) find_asset_by_name(name string) ?Asset {
	return none
}

// has_asset checks if the account contains a specific asset
pub fn (a Account) has_asset(asset_id u32) bool {
	return asset_id in a.assets
}

// remove_asset removes an asset from the account
pub fn (mut a Account) remove_asset(asset_id u32) {
	a.assets = a.assets.filter(it != asset_id)
}