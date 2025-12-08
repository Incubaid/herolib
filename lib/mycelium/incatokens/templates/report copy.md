# INCA Token Economic Simulation Report

## Executive Summary

This report presents the results of the INCA token economic simulation **@{data.sim.name}**, analyzing various market scenarios and their impact on token distribution, pricing, and investor returns.

### Key Parameters

- **Total Token Supply**: @{data.sim.params.distribution.total_supply} INCA
- **Simulation Period**: @{data.sim.params.simulation.nrcol} months
- **Base Currency**: @{data.sim.params.simulation.currency}

## Token Distribution & Allocation

- **Total supply:** @{data.sim.params.distribution.total_supply} INCA
- **Public (TGE):** @{(data.sim.params.distribution.public_pct * 100)}% (No lockup)
- **Team:** @{(data.sim.params.distribution.team_pct * 100)}% (@{data.sim.team_vesting.cliff_months}mo cliff, @{data.sim.team_vesting.vesting_months}mo vest)
- **Treasury:** @{(data.sim.params.distribution.treasury_pct * 100)}% (@{data.sim.treasury_vesting.cliff_months}mo cliff, @{data.sim.treasury_vesting.vesting_months}mo vest)
- **Investors:** @{(data.sim.params.distribution.investor_pct * 100)}%

### Investor Rounds & Vesting

| Round | Allocation | Price (USD) | Vesting Schedule |
|---|---|---|---|
@for round in data.sim.investor_rounds {
| **@{round.name}** | @{(round.allocation_pct * 100)}% | $@{round.price} | @{round.vesting.cliff_months}mo cliff, @{round.vesting.vesting_months}mo linear vest |
}
@end

## Vesting Schedules

### Team Vesting
- **Cliff Period**: @{data.sim.team_vesting.cliff_months} months
- **Vesting Period**: @{data.sim.team_vesting.vesting_months} months
- **Total Team Allocation**: @{(data.sim.params.distribution.total_supply * data.sim.params.distribution.team_pct)} INCA (@{(data.sim.params.distribution.team_pct * 100)}%)

### Treasury Vesting
- **Cliff Period**: @{data.sim.treasury_vesting.cliff_months} months
- **Vesting Period**: @{data.sim.treasury_vesting.vesting_months} months
- **Total Treasury Allocation**: @{(data.sim.params.distribution.total_supply * data.sim.params.distribution.treasury_pct)} INCA (@{(data.sim.params.distribution.treasury_pct * 100)}%)

## Economic Parameters

- **Epoch 1 Floor Uplift**: @{data.sim.params.economics.epoch1_floor_uplift}x
- **Subsequent Epoch Floor Uplift**: @{data.sim.params.economics.epochn_floor_uplift}x
- **AMM Liquidity Depth Factor**: @{data.sim.params.economics.amm_liquidity_depth_factor}x

## Simulation Scenarios

@for name, scenario in data.sim.scenarios {
### @{scenario.name} Scenario
**Parameters:**
- **Auction Demand:** $@{scenario.demands.map(it.str()).join(', ')}
- **AMM Net Trade:** $@{scenario.amm_trades.map(it.str()).join(', ')}

**Results:**
| Treasury Raised | Final Price | @for round in data.sim.investor_rounds {@{round.name} ROI | }|
|:---|:---|@for round in data.sim.investor_rounds {:---|}
| $@{(scenario.final_metrics.treasury_total / 1_000_000):.1f}M | $@{scenario.final_metrics.final_price:.4f} | @for round in data.sim.investor_rounds {@{(scenario.final_metrics.investor_roi[round.name] or { 0.0 }):.2f}x | }

}

## Financial Summary

### Funds Raised for INCA COOP
| Round | USD Raised |
|---|---|
@for round in data.sim.investor_rounds {
| **@{round.name}** | $@{(round.allocation_pct * data.sim.params.distribution.total_supply * round.price)} |
}
| **Total** | **$@{data.total_raised}** |

## Investment Analysis

### Return on Investment by Round

| Investor Round | Price | Allocation | @for scenario_name, _ in data.sim.scenarios {@{scenario_name} ROI | }|
|---|---|---|@for scenario_name, _ in data.sim.scenarios {---|}
@for round in data.sim.investor_rounds {
| **@{round.name}** | $@{round.price} | @{(round.allocation_pct * 100)}% | @for scenario_name, scenario in data.sim.scenarios {@{(scenario.final_metrics.investor_roi[round.name] or { 0.0 }):.2f}x | }
}

## Market Dynamics

### Price Evolution
The token price evolution across different scenarios shows:

| Scenario | Final Price | Price Change |
|---|---|---|
@for name, scenario in data.sim.scenarios {
| **@{name}** | $@{scenario.final_metrics.final_price:.4f} | @{(((scenario.final_metrics.final_price - data.initial_price) / data.initial_price) * 100):+.1f}% |
}

### Market Capitalization
The projected market capitalization ranges show:

| Scenario | Market Cap | Market Cap Range |
|---|---|---|
@for name, scenario in data.sim.scenarios {
| **@{name}** | $@{(scenario.final_metrics.market_cap_final / 1_000_000):.1f}M | Varies by circulating supply |
}

## Risk Analysis

### Scenario Sensitivity
The simulation reveals the following sensitivities:

@for name, scenario in data.sim.scenarios {
- **@{name} Scenario**: @if name == 'Conservative' {Conservative market conditions with limited speculation}@if name == 'Moderate' {Moderate market interest and trading activity}@if name == 'Optimistic' {Strong market demand and active secondary trading}@if name != 'Conservative' && name != 'Moderate' && name != 'Optimistic' {Market scenario with specific demand patterns}
}

### Key Risk Factors
1. **Market Demand Volatility**: Significant impact on final token prices
2. **AMM Pool Dynamics**: Trading activity affects liquidity and price stability
3. **Vesting Schedule Impact**: Lock-up periods influence circulating supply

## Conclusions

Based on the simulation results:

1. **Token Price Sensitivity**: The final token price shows significant sensitivity to market demand levels
2. **Investor Returns**: All investor rounds show positive returns across scenarios
3. **Treasury Funding**: The INCA COOP successfully raises substantial funding through the token sale
4. **Market Dynamics**: The combination of auction and AMM mechanisms provides price discovery and liquidity

The simulation demonstrates a robust token economic model that balances investor returns, treasury funding, and market dynamics.

## Appendices

### A. Methodology
This simulation uses a simplified Dutch auction model combined with AMM (Automated Market Maker) dynamics to project token price evolution.

### B. Assumptions
- All investor rounds are fully subscribed
- Vesting schedules are strictly enforced
- Market dynamics follow the implemented auction and AMM models

---

*Report generated on @{data.generation_date} using INCA Token Simulation Framework*