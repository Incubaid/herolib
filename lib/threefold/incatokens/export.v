module incatokens

import freeflowuniverse.herolib.core.pathlib
import freeflowuniverse.herolib.data.markdown
import os

// // Export simulation results to markdown report
// pub fn (sim &Simulation) export_report(path string) ! {
// 	content := sim.render_report()!
	
// 	// Write to file
// 	mut p := pathlib.get_file(
// 		path: path
// 		create: true
// 		delete: true
// 	)!
// 	p.write(content)!
// }

// Export data to CSV
pub fn (sim Simulation) export_csv(sheet_name string, path string) ! {
	mut sheet := match sheet_name {
		'prices' { sim.price_sheet }
		'tokens' { sim.token_sheet }
		'investments' { sim.investment_sheet }
		'vesting' { sim.vesting_sheet }
		else { return error('Unknown sheet: ${sheet_name}') }
	}
	
	sheet.export_csv(
		path: path
		separator: ','
		include_empty: false
	)!
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