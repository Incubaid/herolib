module incatokens

import math

// AuctionConfig contains the parameters for simulating a Dutch auction.
@[params]
pub struct AuctionConfig {
pub mut:
	demand       f64 // The total USD demand from all participants.
	min_price    f64 // The minimum acceptable price per token (reserve price).
	token_supply f64 // The total number of tokens available for sale.
}


// AuctionResult holds the outcome of a simulated Dutch auction.
pub struct AuctionResult {
pub mut:
	tokens_sold      f64 // The total number of tokens sold.
	clearing_price   f64 // The final price per token.
	usd_raised       f64 // The total funds raised.
	fully_subscribed bool // True if all tokens were sold.
}


// simulate_auction performs a simplified Dutch auction simulation.
// It determines the market-clearing price based on total demand and token supply.
pub fn simulate_auction(config AuctionConfig) !AuctionResult {
	demand := config.demand
	min_price := config.min_price
	token_supply := config.token_supply

	// If there are no tokens to sell, the auction is trivially complete.
	if token_supply <= 0 {
		return AuctionResult{
			tokens_sold: 0
			clearing_price: 0
			usd_raised: 0
			fully_subscribed: true
		}
	}

	// Calculate the implied average price if all tokens were sold given the total demand.
	implied_avg := demand / token_supply

	// Scenario 1: Demand is not high enough to meet the minimum price for all tokens.
	if implied_avg < min_price {
		// The auction clears at the minimum price, resulting in a partial sale.
		// The number of tokens sold is determined by how many can be bought with the total demand at the minimum price.
		tokens_sold := math.min(demand / min_price, token_supply)
		return AuctionResult{
			tokens_sold: tokens_sold
			clearing_price: min_price
			usd_raised: tokens_sold * min_price
			fully_subscribed: tokens_sold >= token_supply
		}
	}

	// Scenario 2: Demand is sufficient to sell all tokens at or above the minimum price.
	// The auction is fully subscribed, and the clearing price is the implied average price.
	return AuctionResult{
		tokens_sold: token_supply
		clearing_price: implied_avg
		usd_raised: demand
		fully_subscribed: true
	}
}

