module finance

// AssetType defines the type of blockchain asset
pub enum AssetType {
	erc20   // ERC-20 token standard
	erc721  // ERC-721 NFT standard
	erc1155 // ERC-1155 Multi-token standard
	native  // Native blockchain asset (e.g., ETH, BTC)
}

// Asset represents a digital asset or token
@[heap]
pub struct Asset {
pub mut:
	id          u32       // Unique asset ID
	name        string    // Name of the asset
	description string    // Description of the asset
	amount      f64       // Amount of the asset
	address     string    // Address of the asset on the blockchain or bank
	asset_type  AssetType // Type of the asset
	decimals    u8        // Number of decimals of the asset (default 18)
	created_at  u64       // Creation timestamp
	updated_at  u64       // Last update timestamp
}

// new creates a new Asset with default values
pub fn Asset.new() Asset {
	return Asset{
		id:          0
		name:        ''
		description: ''
		amount:      0.0
		address:     ''
		asset_type:  .native
		decimals:    18
		created_at:  0
		updated_at:  0
	}
}

// name sets the name of the asset (builder pattern)
pub fn (mut a Asset) name(name string) Asset {
	a.name = name
	return a
}

// description sets the description of the asset (builder pattern)
pub fn (mut a Asset) description(description string) Asset {
	a.description = description
	return a
}

// amount sets the amount of the asset (builder pattern)
pub fn (mut a Asset) amount(amount f64) Asset {
	a.amount = amount
	return a
}

// address sets the address of the asset on the blockchain (builder pattern)
pub fn (mut a Asset) address(address string) Asset {
	a.address = address
	return a
}

// asset_type sets the type of the asset (builder pattern)
pub fn (mut a Asset) asset_type(asset_type AssetType) Asset {
	a.asset_type = asset_type
	return a
}

// decimals sets the number of decimals of the asset (builder pattern)
pub fn (mut a Asset) decimals(decimals u8) Asset {
	a.decimals = decimals
	return a
}

// formatted_amount returns the formatted amount with proper decimal places
pub fn (a Asset) formatted_amount() string {
	factor := f64(1)
	for _ in 0 .. a.decimals {
		factor *= 10
	}
	formatted_amount := (a.amount * factor).round() / factor
	// Format with the specified number of decimal places
	if a.decimals == 0 {
		return '${formatted_amount:.0f}'
	} else if a.decimals == 1 {
		return '${formatted_amount:.1f}'
	} else if a.decimals == 2 {
		return '${formatted_amount:.2f}'
	} else if a.decimals == 3 {
		return '${formatted_amount:.3f}'
	} else if a.decimals == 4 {
		return '${formatted_amount:.4f}'
	} else {
		// For more than 4 decimals, use string manipulation
		str_amount := formatted_amount.str()
		if str_amount.contains('.') {
			parts := str_amount.split('.')
			if parts.len == 2 {
				decimal_part := parts[1]
				if decimal_part.len > a.decimals {
					return '${parts[0]}.${decimal_part[..a.decimals]}'
				}
			}
		}
		return str_amount
	}
}

// transfer_to transfers amount to another asset
pub fn (mut a Asset) transfer_to(mut target Asset, amount f64) ! {
	if amount <= 0.0 {
		return error('Transfer amount must be positive')
	}

	if a.amount < amount {
		return error('Insufficient balance for transfer')
	}

	a.amount -= amount
	target.amount += amount
}
