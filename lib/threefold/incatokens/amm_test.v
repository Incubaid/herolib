module incatokens

import math

// Test initializing and adding liquidity to the AMM pool.
fn test_add_liquidity() {
	mut pool := AMMPool{}
	pool.add_liquidity(1000.0, 500.0)
	assert pool.tokens == 1000.0
	assert pool.usdc == 500.0
	assert pool.k == 500000.0
	price := pool.get_price()
	assert math.abs(price - 0.5) < 0.0001
}

// Test a simple trade where USDC is added to the pool.
fn test_trade() {
	mut pool := AMMPool{}
	pool.add_liquidity(1000.0, 500.0) // Initial price: 0.5 USDC/token
	initial_tokens := pool.tokens
	
	// Trade 100 USDC for tokens
	usdc_to_trade := 100.0
	pool.trade(usdc_to_trade)!
	
	// Verify the new state of the pool
	assert pool.usdc == 600.0
	expected_tokens := pool.k / pool.usdc
	assert math.abs(pool.tokens - expected_tokens) < 0.0001
	
	// Check that tokens were removed from the pool
	tokens_received := initial_tokens - pool.tokens
	assert tokens_received > 0
	
	// Verify the new price (it should be higher)
	new_price := pool.get_price()
	assert new_price > 0.5
}

// Test that the price changes as more trades are executed.
fn test_price_impact() {
	mut pool := AMMPool{}
	pool.add_liquidity(1000.0, 1000.0) // Initial price: 1.0 USDC/token
	
	// First trade
	pool.trade(100.0)!
	price1 := pool.get_price()
	
	// Second trade
	pool.trade(100.0)!
	price2 := pool.get_price()
	
	// The price should increase after each trade
	assert price2 > price1
}

// Test edge case: trading in an empty pool should fail.
fn test_trade_in_empty_pool() {
	mut pool := AMMPool{}
	// The `or` block catches the error from `trade()`.
	// We then assert the error message is what we expect.
	pool.trade(100.0) or {
		expected_error := 'AMM pool is empty and cannot facilitate trades'
		assert err.msg() == expected_error
		return // Exit the test function successfully after catching the error.
	}
	// This line should not be reached if the error is caught correctly.
	assert false, 'Expected trade to fail, but it succeeded'
}

// Test edge case: price calculation in an empty pool.
fn test_get_price_in_empty_pool() {
	pool := AMMPool{}
	price := pool.get_price()
	assert price == 0.0
}