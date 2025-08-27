# INCA Token Economic Simulation Report

## Executive Summary

This report presents the results of the INCA token economic simulation **{{.name}}**, analyzing various market scenarios and their impact on token distribution, pricing, and investor returns.

### Key Parameters

- **Total Token Supply**: {{.total_supply}} INCA
- **Simulation Period**: {{.nrcol}} months
- **Base Currency**: {{.currency}}

## Token Distribution & Allocation

{{.distribution_section}}

## Vesting Schedules

### Team Vesting
- **Cliff Period**: {{.team_cliff_months}} months
- **Vesting Period**: {{.team_vesting_months}} months  
- **Total Team Allocation**: {{.team_allocation}} INCA ({{.team_pct}}%)

### Treasury Vesting
- **Cliff Period**: {{.treasury_cliff_months}} months
- **Vesting Period**: {{.treasury_vesting_months}} months
- **Total Treasury Allocation**: {{.treasury_allocation}} INCA ({{.treasury_pct}}%)

## Economic Parameters

- **Epoch 1 Floor Uplift**: {{.epoch1_floor_uplift}}x
- **Subsequent Epoch Floor Uplift**: {{.epochn_floor_uplift}}x
- **AMM Liquidity Depth Factor**: {{.amm_liquidity_depth_factor}}x

## Simulation Scenarios

{{.scenarios_section}}

## Financial Summary

{{.financial_summary}}

## Investment Analysis

### Return on Investment by Round

{{.roi_analysis}}

## Market Dynamics

### Price Evolution
The token price evolution across different scenarios shows:

{{.price_analysis}}

### Market Capitalization
The projected market capitalization ranges show:

{{.market_cap_analysis}}

## Risk Analysis

### Scenario Sensitivity
The simulation reveals the following sensitivities:

- **Low Demand Scenario**: Conservative market conditions with limited speculation
- **Medium Demand Scenario**: Moderate market interest and trading activity  
- **High Demand Scenario**: Strong market demand and active secondary trading

### Key Risk Factors
1. **Market Demand Volatility**: Significant impact on final token prices
2. **AMM Pool Dynamics**: Trading activity affects liquidity and price stability
3. **Vesting Schedule Impact**: Lock-up periods influence circulating supply

## Conclusions

{{.conclusions}}

## Appendices

### A. Methodology
This simulation uses a simplified Dutch auction model combined with AMM (Automated Market Maker) dynamics to project token price evolution.

### B. Assumptions
- All investor rounds are fully subscribed
- Vesting schedules are strictly enforced
- Market dynamics follow the implemented auction and AMM models

---

*Report generated on {{.generation_date}} using INCA Token Simulation Framework*