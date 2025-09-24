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
@for round in data.sim.investor_rounds
| **@{round.name}** | @{(round.allocation_pct * 100)}% | $@{round.price} | @{round.vesting.cliff_months}mo cliff, @{round.vesting.vesting_months}mo linear vest |
@end

