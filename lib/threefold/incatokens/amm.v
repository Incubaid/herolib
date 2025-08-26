module incatokens

import math

pub struct AMMPool {
pub mut:
	tokens f64
	usdc f64
	k f64 // constant product
}

pub fn (mut pool AMMPool) add_liquidity(tokens f64, usdc f64) {
	pool.tokens += tokens
	pool.usdc += usdc
	pool.k = pool.tokens * pool.usdc
}

pub fn (mut pool AMMPool) trade(usdc_amount f64) ! {
	if pool.tokens <= 0 || pool.usdc <= 0 {
		return error('AMM pool is empty')
	}
	
	pool.usdc += usdc_amount
	
	if pool.usdc <= 0 {
		return error('Insufficient USDC in pool')
	}
	
	// Maintain constant product
	pool.tokens = pool.k / pool.usdc
}

pub fn (pool AMMPool) get_price() f64 {
	if pool.tokens <= 0 {
		return 0
	}
	return pool.usdc / pool.tokens
}