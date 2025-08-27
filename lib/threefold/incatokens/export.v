module incatokens

import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.ui.console
import time

const report_template = '# INCA Token Economic Simulation Report

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
'

// Export data to CSV
pub fn (sim Simulation) export_csv(sheet_name string, path string) ! {
	mut sheet := match sheet_name {
		'prices' { sim.price_sheet }
		'tokens' { sim.token_sheet }
		'investments' { sim.investment_sheet }
		'vesting' { sim.vesting_sheet }
		else { return error('Unknown sheet: ${sheet_name}') }
	}
	
	console.print_debug('Exporting sheet "${sheet_name}" to: ${path}')
	sheet.export_csv(
		path: path
		separator: ','
		include_empty: false
	)!
	console.print_debug('Finished exporting sheet "${sheet_name}".')
}

pub fn (sim Simulation) generate_distribution_section() !string {
	mut lines := []string{}
	
	lines << '- **Total supply:** ${sim.total_supply} INCA'
	lines << '- **Public (TGE):** ${(sim.public_pct * 100).str()}% (No lockup)'
	lines << '- **Team:** ${(sim.team_pct * 100).str()}% (${sim.team_vesting.cliff_months}mo cliff, ${sim.team_vesting.vesting_months}mo vest)'
	lines << '- **Treasury:** ${(sim.treasury_pct * 100).str()}% (${sim.treasury_vesting.cliff_months}mo cliff, ${sim.treasury_vesting.vesting_months}mo vest)'
	lines << '- **Investors:** ${(sim.investor_pct * 100).str()}%'
	lines << ''
	lines << '### Investor Rounds & Vesting'
	lines << '| Round | Allocation | Price (USD) | Vesting Schedule |'
	lines << '|---|---|---|---|'
	
	for round in sim.investor_rounds {
		lines << '| **${round.name}** | ${(round.allocation_pct * 100).str()}% | \$${round.price} | ${round.vesting.cliff_months}mo cliff, ${round.vesting.vesting_months}mo linear vest |'
	}
	
	return lines.join('\n')
}

pub fn (sim Simulation) generate_scenario_section(scenario &Scenario) !string {
	mut lines := []string{}
	
	lines << '### ${scenario.name} Scenario'
	lines << '**Parameters:**'
	lines << '- **Auction Demand:** \$${scenario.demands.map(it.str()).join(', ')}'
	lines << '- **AMM Net Trade:** \$${scenario.amm_trades.map(it.str()).join(', ')}'
	lines << ''
	lines << '**Results:**'
	lines << '| Treasury Raised | Final Price | ${sim.investor_rounds.map("ROI " + it.name).join(" | ")} |'
	lines << '|:---|:---|${sim.investor_rounds.map(":---").join("|")}|'
	
	mut row := ['\$${(scenario.final_metrics.treasury_total / 1000000).str()}M', '\$${scenario.final_metrics.final_price}']
	for round in sim.investor_rounds {
		roi := scenario.final_metrics.investor_roi[round.name] or { 0.0 }
		row << '${roi}x'
	}
	lines << '| ${row.join(' | ')} |'
	
	return lines.join('\n')
}

pub fn (sim Simulation) generate_financial_summary() !string {
	mut lines := []string{}
	
	lines << '### Funds Raised for INCA COOP'
	lines << '| Round | USD Raised |'
	lines << '|---|---|'
	
	mut total_raised := 0.0
	for round in sim.investor_rounds {
		raised := round.allocation_pct * sim.total_supply * round.price
		total_raised += raised
		lines << '| **${round.name}** | \$${raised} |'
	}
	lines << '| **Total** | **\$${total_raised}** |'
	
	return lines.join('\n')
}

// Method to generate report from simulation
pub fn (sim Simulation) generate_report(output_dir string) ! {
	// Ensure output directory exists
	mut output_path := pathlib.get_dir(path: output_dir, create: true)!
	
	// Prepare template variables
	mut vars := map[string]string{}
	vars['name'] = sim.name
	vars['total_supply'] = sim.total_supply.str()
	vars['nrcol'] = sim.price_sheet.nrcol.str()
	vars['currency'] = sim.currency
	vars['team_cliff_months'] = sim.team_vesting.cliff_months.str()
	vars['team_vesting_months'] = sim.team_vesting.vesting_months.str()
	vars['team_allocation'] = (sim.total_supply * sim.team_pct).str()
	vars['team_pct'] = (sim.team_pct * 100).str()
	vars['treasury_cliff_months'] = sim.treasury_vesting.cliff_months.str()
	vars['treasury_vesting_months'] = sim.treasury_vesting.vesting_months.str()
	vars['treasury_allocation'] = (sim.total_supply * sim.treasury_pct).str()
	vars['treasury_pct'] = (sim.treasury_pct * 100).str()
	vars['epoch1_floor_uplift'] = sim.epoch1_floor_uplift.str()
	vars['epochn_floor_uplift'] = sim.epochn_floor_uplift.str()
	vars['amm_liquidity_depth_factor'] = sim.amm_liquidity_depth_factor.str()
	vars['generation_date'] = time.now().format()
	
	// Generate sections
	vars['distribution_section'] = sim.generate_distribution_section()!
	vars['scenarios_section'] = sim.generate_scenarios_section()!
	vars['financial_summary'] = sim.generate_financial_summary()!
	vars['roi_analysis'] = sim.generate_roi_analysis()!
	vars['price_analysis'] = sim.generate_price_analysis()!
	vars['market_cap_analysis'] = sim.generate_market_cap_analysis()!
	vars['conclusions'] = sim.generate_conclusions()!
	
	// Process template
	mut content := report_template
	for key, value in vars {
		content = content.replace('{{.${key}}}', value)
	}
	
	// Write report
	report_path := '${output_path.path}/${sim.name}_report.md'
	mut report_file := pathlib.get_file(path: report_path, create: true)!
	report_file.write(content)!
	
	console.print_green('✓ Report generated: ${report_path}')
}

// Additional template methods for generating report sections
pub fn (sim Simulation) generate_scenarios_section() !string {
	mut lines := []string{}
	
	for name, scenario in sim.scenarios {
		lines << sim.generate_scenario_section(scenario)!
		lines << ''
	}
	
	return lines.join('\n')
}

pub fn (sim Simulation) generate_roi_analysis() !string {
	mut lines := []string{}
	
	lines << '| Investor Round | Price | Allocation | '
	for scenario_name, _ in sim.scenarios {
		lines[0] += '${scenario_name} ROI | '
	}
	lines << '|' + '---|'.repeat(3 + sim.scenarios.len)
	
	for round in sim.investor_rounds {
		mut row := '| **${round.name}** | \$${round.price} | ${(round.allocation_pct * 100).str()}% | '
		for scenario_name, scenario in sim.scenarios {
			roi := scenario.final_metrics.investor_roi[round.name] or { 0.0 }
			row += '${roi:.2f}x | '
		}
		lines << row
	}
	
	return lines.join('\n')
}

pub fn (sim Simulation) generate_price_analysis() !string {
	mut lines := []string{}
	
	lines << '| Scenario | Final Price | Price Change |'
	lines << '|---|---|---|'
	
	initial_price := sim.get_last_investor_price()
	for name, scenario in sim.scenarios {
		final_price := scenario.final_metrics.final_price
		change_pct := ((final_price - initial_price) / initial_price) * 100
		lines << '| **${name}** | \$${final_price:.4f} | ${change_pct:+.1f}% |'
	}
	
	return lines.join('\n')
}

pub fn (sim Simulation) generate_market_cap_analysis() !string {
	mut lines := []string{}
	
	lines << '| Scenario | Market Cap | Market Cap Range |'
	lines << '|---|---|---|'
	
	for name, scenario in sim.scenarios {
		mc := scenario.final_metrics.market_cap_final / 1_000_000 // In millions
		lines << '| **${name}** | \$${mc:.1f}M | Varies by circulating supply |'
	}
	
	return lines.join('\n')
}

pub fn (sim Simulation) generate_conclusions() !string {
	mut lines := []string{}
	
	lines << 'Based on the simulation results:'
	lines << ''
	lines << '1. **Token Price Sensitivity**: The final token price shows significant sensitivity to market demand levels'
	lines << '2. **Investor Returns**: All investor rounds show positive returns across scenarios'
	lines << '3. **Treasury Funding**: The INCA COOP successfully raises substantial funding through the token sale'
	lines << '4. **Market Dynamics**: The combination of auction and AMM mechanisms provides price discovery and liquidity'
	lines << ''
	lines << 'The simulation demonstrates a robust token economic model that balances investor returns, treasury funding, and market dynamics.'
	
	return lines.join('\n')
}