#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import freeflowuniverse.herolib.data.countries

mut all_countries := countries.get_all_countries() or {
	eprintln('Error loading countries: ${err}')
	return
}

println('Total countries loaded: ${all_countries.len}')

// --- Example: Print the first few countries ---
println('\n--- First 5 Countries ---')
for i, country in all_countries {
	if i >= 5 {
		break
	}
	println(country.str())
}

// --- Example: Find a specific country (e.g., Belgium) ---
println('\n--- Searching for Belgium ---')
mut found := false
for country in all_countries {
	if country.iso == 'BE' {
		println('Found Belgium: ${country.str()}')
		found = true
		break
	}
}
if !found {
	println('Belgium not found.')
}

// --- Example: Find countries in Europe (Continent = EU) ---
println('\n--- Countries in Europe (EU) ---')
mut eu_countries := []countries.Country{}
for country in all_countries {
	if country.continent == 'EU' {
		eu_countries << country
	}
}
println('Found ${eu_countries.len} European countries.')
// Optionally print them or process further

// --- Example: Using the helper function ---
println('\n--- Using helper function to find Japan ---')
japan := countries.find_country_by_iso('JP') or {
	println('Error finding Japan: ${err}')
	return
}
println('Found Japan: ${japan.str()}')
