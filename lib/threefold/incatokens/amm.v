module incatokens

import math

// AMMPool represents a simple Automated Market Maker pool.
// It uses the constant product formula (x * y = k) to determine prices.
pub struct AMMPool {
pub mut:
	tokens f64 // The total number of tokens in the pool.
	usdc   f64 // The total amount of USDC (stablecoin) in the pool.
	k      f64 // The constant product (k = tokens * usdc).
}

// add_liquidity adds tokens and USDC to the pool, updating the constant product.
// This function is used to provide liquidity to the AMM.
pub fn (mut pool AMMPool) add_liquidity(tokens f64, usdc f64) {
	pool.tokens += tokens
	pool.usdc += usdc
	pool.k = pool.tokens * pool.usdc
}

// trade executes a swap by adding USDC to the pool and removing tokens.
// The amount of tokens removed is calculated to maintain the constant product `k`.
pub fn (mut pool AMMPool) trade(usdc_amount f64) ! {
	if pool.tokens <= 0 || pool.usdc <= 0 {
		return error('AMM pool is empty and cannot facilitate trades')
	}

	pool.usdc += usdc_amount

	if pool.usdc <= 0 {
		return error('USDC in the pool cannot be zero or negative after a trade')
	}

	// Re-calculate the number of tokens to maintain the constant product `k`.
	pool.tokens = pool.k / pool.usdc
}

// get_price calculates the current price of a single token in USDC.
// The price is determined by the ratio of USDC to tokens in the pool.
pub fn (pool AMMPool) get_price() f64 {
	if pool.tokens <= 0 {
		return 0 // Avoid division by zero if there are no tokens in the pool.
	}
	return pool.usdc / pool.tokens
}