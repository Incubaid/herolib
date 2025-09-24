module finance

import time

// ListingStatus defines the status of a marketplace listing
pub enum ListingStatus {
	active    // Listing is active and available
	sold      // Listing has been sold
	cancelled // Listing was cancelled by the seller
	expired   // Listing has expired
}

// ListingType defines the type of marketplace listing
pub enum ListingType {
	fixed_price // Fixed price sale
	auction     // Auction with bids
	exchange    // Exchange for other assets
}

// BidStatus defines the status of a bid on an auction listing
pub enum BidStatus {
	active    // Bid is active
	accepted  // Bid was accepted
	rejected  // Bid was rejected
	cancelled // Bid was cancelled by the bidder
}

// Bid represents a bid on an auction listing
pub struct Bid {
pub mut:
	listing_id string    // ID of the listing this bid belongs to
	bidder_id  u32       // ID of the user who placed the bid
	amount     f64       // Bid amount
	currency   string    // Currency of the bid
	status     BidStatus // Status of the bid
	created_at u64       // When the bid was created
}

// new creates a new Bid with default values
pub fn Bid.new() Bid {
	return Bid{
		listing_id: ''
		bidder_id:  0
		amount:     0.0
		currency:   ''
		status:     .active
		created_at: u64(time.now().unix_time())
	}
}

// listing_id sets the listing ID for the bid (builder pattern)
pub fn (mut b Bid) listing_id(listing_id string) Bid {
	b.listing_id = listing_id
	return b
}

// bidder_id sets the bidder ID for the bid (builder pattern)
pub fn (mut b Bid) bidder_id(bidder_id u32) Bid {
	b.bidder_id = bidder_id
	return b
}

// amount sets the amount for the bid (builder pattern)
pub fn (mut b Bid) amount(amount f64) Bid {
	b.amount = amount
	return b
}

// currency sets the currency for the bid (builder pattern)
pub fn (mut b Bid) currency(currency string) Bid {
	b.currency = currency
	return b
}

// status sets the status of the bid (builder pattern)
pub fn (mut b Bid) status(status BidStatus) Bid {
	b.status = status
	return b
}

// Listing represents a marketplace listing for an asset
@[heap]
pub struct Listing {
pub mut:
	id           u32           // Unique listing ID
	title        string        // Title of the listing
	description  string        // Description of the listing
	asset_id     string        // ID of the asset being listed
	asset_type   AssetType     // Type of the asset
	seller_id    string        // ID of the user selling the asset
	price        f64           // Initial price for fixed price, or starting price for auction
	currency     string        // Currency of the listing
	listing_type ListingType   // Type of listing (fixed_price, auction, exchange)
	status       ListingStatus // Status of the listing
	expires_at   ?u64          // Optional expiration date
	sold_at      ?u64          // Optional date when the item was sold
	buyer_id     ?string       // Optional buyer ID
	sale_price   ?f64          // Optional final sale price
	bids         []Bid         // List of bids for auction type listings
	tags         []string      // Tags for the listing
	image_url    ?string       // Optional image URL
	created_at   u64           // Creation timestamp
	updated_at   u64           // Last update timestamp
}

// new creates a new Listing with default values
pub fn Listing.new() Listing {
	now := u64(time.now().unix_time())
	return Listing{
		id:           0
		title:        ''
		description:  ''
		asset_id:     ''
		asset_type:   .native
		seller_id:    ''
		price:        0.0
		currency:     ''
		listing_type: .fixed_price
		status:       .active
		expires_at:   none
		sold_at:      none
		buyer_id:     none
		sale_price:   none
		bids:         []
		tags:         []
		image_url:    none
		created_at:   now
		updated_at:   now
	}
}

// title sets the title of the listing (builder pattern)
pub fn (mut l Listing) title(title string) Listing {
	l.title = title
	return l
}

// description sets the description of the listing (builder pattern)
pub fn (mut l Listing) description(description string) Listing {
	l.description = description
	return l
}

// asset_id sets the asset ID of the listing (builder pattern)
pub fn (mut l Listing) asset_id(asset_id string) Listing {
	l.asset_id = asset_id
	return l
}

// asset_type sets the asset type of the listing (builder pattern)
pub fn (mut l Listing) asset_type(asset_type AssetType) Listing {
	l.asset_type = asset_type
	return l
}

// seller_id sets the seller ID of the listing (builder pattern)
pub fn (mut l Listing) seller_id(seller_id string) Listing {
	l.seller_id = seller_id
	return l
}

// price sets the price of the listing (builder pattern)
pub fn (mut l Listing) price(price f64) Listing {
	l.price = price
	return l
}

// currency sets the currency of the listing (builder pattern)
pub fn (mut l Listing) currency(currency string) Listing {
	l.currency = currency
	return l
}

// listing_type sets the listing type (builder pattern)
pub fn (mut l Listing) listing_type(listing_type ListingType) Listing {
	l.listing_type = listing_type
	return l
}

// status sets the status of the listing (builder pattern)
pub fn (mut l Listing) status(status ListingStatus) Listing {
	l.status = status
	return l
}

// expires_at sets the expiration date of the listing (builder pattern)
pub fn (mut l Listing) expires_at(expires_at ?u64) Listing {
	l.expires_at = expires_at
	return l
}

// image_url sets the image URL of the listing (builder pattern)
pub fn (mut l Listing) image_url(image_url ?string) Listing {
	l.image_url = image_url
	return l
}

// add_bid adds a bid to an auction listing
pub fn (mut l Listing) add_bid(bid Bid) ! {
	// Check if listing is an auction
	if l.listing_type != .auction {
		return error('Cannot add bid to non-auction listing')
	}

	// Check if listing is active
	if l.status != .active {
		return error('Cannot place bid on inactive listing')
	}

	// Check if bid amount is higher than current price
	if bid.amount <= l.price {
		return error('Bid amount must be higher than current price')
	}

	// Check if there are existing bids and if the new bid is higher
	if highest_bid := l.highest_bid() {
		if bid.amount <= highest_bid.amount {
			return error('Bid amount must be higher than current highest bid')
		}
	}

	// Add the bid
	l.bids << bid

	// Update the current price to the new highest bid
	if highest_bid := l.highest_bid() {
		l.price = highest_bid.amount
	}
}

// highest_bid gets the highest active bid
pub fn (l Listing) highest_bid() ?Bid {
	mut highest := ?Bid(none)
	for bid in l.bids {
		if bid.status == .active {
			if highest_bid := highest {
				if bid.amount > highest_bid.amount {
					highest = bid
				}
			} else {
				highest = bid
			}
		}
	}
	return highest
}

// buyer_id sets the buyer ID for completing a sale (builder pattern)
pub fn (mut l Listing) buyer_id(buyer_id string) Listing {
	l.buyer_id = buyer_id
	return l
}

// sale_price sets the sale price for completing a sale (builder pattern)
pub fn (mut l Listing) sale_price(sale_price f64) Listing {
	l.sale_price = sale_price
	return l
}

// sold_at sets the sold date for completing a sale (builder pattern)
pub fn (mut l Listing) sold_at(sold_at ?u64) Listing {
	l.sold_at = sold_at
	return l
}

// complete_sale completes a sale (fixed price or auction)
pub fn (mut l Listing) complete_sale() ! {
	if l.status != .active {
		return error('Cannot complete sale for inactive listing')
	}

	if l.buyer_id == none {
		return error('Buyer ID must be set before completing sale')
	}

	if l.sale_price == none {
		return error('Sale price must be set before completing sale')
	}

	l.status = .sold

	if l.sold_at == none {
		l.sold_at = u64(time.now().unix_time())
	}

	// If this was an auction, accept the winning bid and reject others
	if l.listing_type == .auction {
		buyer_id_str := l.buyer_id or { '' }
		sale_price_val := l.sale_price or { 0.0 }

		for mut bid in l.bids {
			if bid.bidder_id.str() == buyer_id_str && bid.amount == sale_price_val {
				bid.status = .accepted
			} else {
				bid.status = .rejected
			}
		}
	}
}

// cancel cancels the listing
pub fn (mut l Listing) cancel() ! {
	if l.status != .active {
		return error('Cannot cancel inactive listing')
	}

	l.status = .cancelled

	// Cancel all active bids
	for mut bid in l.bids {
		if bid.status == .active {
			bid.status = .cancelled
		}
	}
}

// check_expiration checks if the listing has expired and updates status if needed
pub fn (mut l Listing) check_expiration() {
	if l.status == .active {
		if expires_at := l.expires_at {
			if u64(time.now().unix_time()) > expires_at {
				l.status = .expired

				// Cancel all active bids
				for mut bid in l.bids {
					if bid.status == .active {
						bid.status = .cancelled
					}
				}
			}
		}
	}
}

// add_tag adds a single tag to the listing (builder pattern)
pub fn (mut l Listing) add_tag(tag string) Listing {
	l.tags << tag
	return l
}
