module incatokens

import math

// Test case 1: Full subscription
// The implied average price ($1.25) is higher than the minimum price ($0.5),
// so all tokens are sold at the market-clearing price.
fn test_simulate_auction_full_subscription() {
	config := AuctionConfig{
		demand: 125000.0
		min_price: 0.5
		token_supply: 100000.0
	}
	res := simulate_auction(config)!
	assert res.tokens_sold == 100000.0
	assert res.clearing_price == 1.25
	assert res.usd_raised == 125000.0
	assert res.fully_subscribed == true
}

// Test case 2: Partial fill
// The implied average price ($0.4) is lower than the minimum price ($0.5).
// The auction clears at the minimum price, and only a portion of tokens are sold.
fn test_simulate_auction_partial_fill() {
	config := AuctionConfig{
		demand: 40000.0
		min_price: 0.5
		token_supply: 100000.0
	}
	res := simulate_auction(config)!
	// We can only sell as many tokens as the demand can afford at the min_price
	expected_tokens_sold := config.demand / config.min_price // 40000 / 0.5 = 80000
	assert res.tokens_sold == expected_tokens_sold
	assert res.clearing_price == 0.5
	assert res.usd_raised == 40000.0
	assert res.fully_subscribed == false
}

// Test case 3: Zero token supply
// If there are no tokens to sell, the auction should result in zero sales and fundraising.
fn test_simulate_auction_zero_supply() {
	config := AuctionConfig{
		demand: 50000.0
		min_price: 0.5
		token_supply: 0
	}
	res := simulate_auction(config)!
	assert res.tokens_sold == 0
	assert res.clearing_price == 0
	assert res.usd_raised == 0
	assert res.fully_subscribed == true // Considered fully subscribed as there's nothing to sell
}

// Test case 4: Demand exactly meets the minimum price
// The implied average price is exactly the minimum price.
// The auction should be fully subscribed at the minimum price.
fn test_simulate_auction_demand_equals_min_price() {
	config := AuctionConfig{
		demand: 50000.0
		min_price: 0.5
		token_supply: 100000.0
	}
	res := simulate_auction(config)!
	assert res.tokens_sold == 100000.0
	assert res.clearing_price == 0.5
	assert res.usd_raised == 50000.0
	assert res.fully_subscribed == true
}