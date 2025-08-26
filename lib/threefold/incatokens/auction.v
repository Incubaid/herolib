module incatokens

import math
pub struct AuctionResult {
pub mut:
	tokens_sold f64
	clearing_price f64
	usd_raised f64
	fully_subscribed bool
}

pub fn simulate_auction(config AuctionConfig) !AuctionResult {
	demand := config.demand
	min_price := config.min_price
	token_supply := config.token_supply
	
	if token_supply <= 0 {
		return AuctionResult{
			tokens_sold: 0
			clearing_price: 0
			usd_raised: 0
			fully_subscribed: true
		}
	}
	
	implied_avg := demand / token_supply
	
	if implied_avg < min_price {
		// Partial fill at floor price
		tokens_sold := math.min(demand / min_price, token_supply)
		return AuctionResult{
			tokens_sold: tokens_sold
			clearing_price: min_price
			usd_raised: tokens_sold * min_price
			fully_subscribed: tokens_sold >= token_supply
		}
	}
	
	// Full subscription at market clearing price
	return AuctionResult{
		tokens_sold: token_supply
		clearing_price: implied_avg
		usd_raised: demand
		fully_subscribed: true
	}
}

@[params]
pub struct AuctionConfig {
pub mut:
	demand f64
	min_price f64
	token_supply f64
}