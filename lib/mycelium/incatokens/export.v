module incatokens

import incubaid.herolib.core.pathlib
import incubaid.herolib.ui.console
import time

// Struct to hold all data for the report template
pub struct ReportData {
pub mut:
	sim             &Simulation
	generation_date string
	total_raised    f64
	initial_price   f64
}

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
		path:          path
		separator:     ','
		include_empty: false
	)!
	console.print_debug('Finished exporting sheet "${sheet_name}".')
}

// Generate a single scenario section for use in templates
pub fn (sim Simulation) generate_scenario_section(scenario_name string) !string {
	scenario := sim.scenarios[scenario_name] or {
		return error('Scenario not found: ${scenario_name}')
	}

	mut lines := []string{}
	lines << '### ${scenario.name} Scenario'
	lines << '**Parameters:**'
	lines << '- **Auction Demand:** \$${scenario.demands.map(it.str()).join(', ')}'
	lines << '- **AMM Net Trade:** \$${scenario.amm_trades.map(it.str()).join(', ')}'
	lines << ''
	lines << '**Results:**'

	// Create table header
	mut header := ['Treasury Raised', 'Final Price']
	for round in sim.investor_rounds {
		header << 'ROI ${round.name}'
	}
	lines << '| ${header.join(' | ')} |'

	// Create separator row
	mut separator := [':---', ':---']
	for _ in sim.investor_rounds {
		separator << ':---'
	}
	lines << '| ${separator.join('|')} |'

	// Create data row
	mut row := ['\$${(scenario.final_metrics.treasury_total / 1_000_000):.1f}M',
		'\$${scenario.final_metrics.final_price:.4f}']
	for round in sim.investor_rounds {
		roi := scenario.final_metrics.investor_roi[round.name] or { 0.0 }
		row << '${roi:.2f}x'
	}
	lines << '| ${row.join(' | ')} |'

	return lines.join('\n')
}

// Calculate total funds raised across all investor rounds
fn (sim Simulation) calculate_total_raised() f64 {
	mut total := 0.0
	for round in sim.investor_rounds {
		raised := round.allocation_pct * sim.params.distribution.total_supply * round.price
		total += raised
	}
	return total
}

pub fn (sim Simulation) generate_report(output_dir string) ! {
	// Ensure output directory exists
	mut output_path := pathlib.get_dir(path: output_dir, create: true)!

	// Prepare template variables
	data := ReportData{
		sim:             &sim
		generation_date: time.now().format()
		total_raised:    sim.calculate_total_raised()
		initial_price:   sim.get_last_investor_price()
	}

	// Process template
	content := $tmpl('templates/report.md')

	// Write report
	report_path := '${output_path.path}/${sim.name}_report.md'
	mut report_file := pathlib.get_file(path: report_path, create: true)!
	report_file.write(content)!

	console.print_green('✓ Report generated: ${report_path}')
}
